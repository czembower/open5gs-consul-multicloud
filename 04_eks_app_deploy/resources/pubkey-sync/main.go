package main

import (
	"context"
	"crypto/x509"
	"encoding/pem"
	"log"
	"os"
	"time"

	v1 "k8s.io/api/core/v1"
	metaV1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func getSaCaPubKey() string {
	saCaCert, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
	if err != nil {
		log.Fatalf("error loading ca.crt file: %v", err)
	}

	certPem, _ := pem.Decode(saCaCert)
	if err != nil {
		log.Fatalf("error decoding ca.crt PEM data: %v", err)
	}

	cert, err := x509.ParseCertificate(certPem.Bytes)
	if err != nil {
		log.Fatalf("error parsing ca.crt: %v", err)
	}

	publicKeyDer, _ := x509.MarshalPKIXPublicKey(cert.PublicKey)

	publicKeyBlock := pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: publicKeyDer,
	}
	publicKeyPem := string(pem.EncodeToMemory(&publicKeyBlock))

	return publicKeyPem
}

func createK8sSecret(pubkey string) {
	config, err := rest.InClusterConfig()
	if err != nil {
		log.Fatalf("error initializing kubernetes client config: %v", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("error initializing kubernetes client: %v", err)
	}

	namespace, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")

	secret := &v1.Secret{
		ObjectMeta: metaV1.ObjectMeta{
			Name:      "sa-public-key",
			Namespace: string(namespace),
		},
		StringData: map[string]string{
			"sa.pub": pubkey,
		},
	}

	if err != nil {
		log.Fatalf("error retrieving namespace: %v", err)
	}
	secretsClient := clientset.CoreV1().Secrets(string(namespace))
	_, err = secretsClient.Create(context.TODO(), secret, metaV1.CreateOptions{})

	if err != nil {
		_, err = secretsClient.Update(context.TODO(), secret, metaV1.UpdateOptions{})
		if err != nil {
			log.Fatalf("error updating kubernetes secret: %v", err)
		}
	}
}

func main() {
	for {
		pubKeyString := getSaCaPubKey()
		createK8sSecret(pubKeyString)
		time.Sleep(60 * time.Second)
	}
}
