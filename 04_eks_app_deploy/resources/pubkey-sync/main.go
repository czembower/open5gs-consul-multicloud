package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt"
	"github.com/lestrrat-go/jwx/jwk"
	v1 "k8s.io/api/core/v1"
	metaV1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func getSaToken() (string, string, string) {
	var issuer string
	var kid string
	var expiration time.Time
	nowTime := time.Now().Unix()
	saToken, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/token")
	tokenString := string(saToken)

	if err != nil {
		log.Fatalf("%v", err)
	}

	token, _, err := new(jwt.Parser).ParseUnverified(tokenString, jwt.MapClaims{})

	if err != nil {
		log.Fatalf("error parsing service account token: %v", err)
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		switch exp := claims["exp"].(type) {
		case float64:
			expiration = time.Unix(int64(exp), 0)
		case json.Number:
			v, _ := exp.Int64()
			expiration = time.Unix(v, 0)
		}
		if nowTime-expiration.Unix() > 0 {
			log.Println("token expired")
		}
		issuer = claims["iss"].(string)
		kid = claims["kid"].(string)
	} else {
		log.Fatalf("error unmarshalling jwt claims: %v", err)
	}

	return tokenString, issuer, kid
}

func getK8sJwksData() ([]byte, string) {
	saToken, _, kid := getSaToken()
	authString := fmt.Sprintf("Bearer %s", saToken)
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	httpClient := &http.Client{
		Timeout:   5 * time.Second,
		Transport: tr,
	}

	req, _ := http.NewRequest("GET", "https://kubernetes/openid/v1/jwks", nil)
	req.Header.Add("Authorization", authString)
	resp, err := httpClient.Do(req)
	if err != nil {
		panic(err.Error())
	}

	var payload map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&payload)
	if err != nil {
		panic(err.Error())
	}

	jwks, err := json.Marshal(payload)
	if err != nil {
		panic(err.Error())
	}

	log.Printf("K8s JWKS JSON-marshalled payload: %s\n", jwks)

	return jwks, kid
}

func getOidcJwksData() ([]byte, string) {
	httpClient := &http.Client{
		Timeout: 5 * time.Second,
	}

	_, issuer, kid := getSaToken()

	req, _ := http.NewRequest("GET", issuer+"/keys", nil)
	resp, err := httpClient.Do(req)
	if err != nil {
		panic(err.Error())
	}

	var payload map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&payload)
	if err != nil {
		panic(err.Error())
	}

	jwks, err := json.Marshal(payload)
	if err != nil {
		panic(err.Error())
	}

	log.Printf("OIDC JWKS JSON-marshalled payload: %s\n", jwks)

	return jwks, kid
}

func jwks2pem(jwksData []byte) string {
	set, err := jwk.Parse(jwksData)
	if err != nil {
		log.Fatal("JWKS parsing failed")
	} else {
		log.Println("Successfully parsed JWKS:", string(jwksData))
	}

	pem, err := jwk.Pem(set)
	if err != nil {
		log.Fatal("PEM conversion failed")
	} else {
		log.Println("Sucessfully converted JWKS to PEM format:", strings.ReplaceAll(strings.TrimSpace(string(pem)), "\n", `\n`))
	}
	pemString := strings.TrimSpace(string(pem))

	return pemString
}

func createK8sSecret(secretName string, kid string, pubkey string) {
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
			Name:      secretName + "-sa-public-key",
			Namespace: string(namespace),
		},
		StringData: map[string]string{
			"kid":    kid,
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
	log.Println("pubkey-sync started")
	for {
		k8sJwksData, k8sKid := getK8sJwksData()
		oidcJwksData, oidcKid := getOidcJwksData()

		k8sSaPem := jwks2pem(k8sJwksData)
		oidcSaPem := jwks2pem(oidcJwksData)

		createK8sSecret("k8s", k8sKid, k8sSaPem)
		createK8sSecret("oidc", oidcKid, oidcSaPem)
		time.Sleep(60 * time.Second)
	}
}
