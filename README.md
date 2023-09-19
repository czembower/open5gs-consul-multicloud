# open5gs-consul-multicloud

Notes on troubleshooting and next steps:

Finally realizing what the k8s authentication issue is. When you first create an EKS cluster, the only IAM roles/identities that
are allowed to access the cluster are the creator and the managed nodes.

In this case, the creator was chris.zembower@hashicorp.com via assumeRole, due to the the fact that my IAM credentials are passed into
the provider for the 01_infra workspace. A kubernetes auth token generated by any entity other than that account will fail to validate.

Therefore, the path forward is probably to have a base workspace that provisions all of the TFC workspaces, creates an agent, and then assigns
all of those workspaces to agent execution mode. This will ensure that all suqsequent authentication will succeed via that agent, where we
will run all further provisioning.