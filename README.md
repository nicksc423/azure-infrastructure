# azure-infrastructure

## NOTES ##

* Creating AzureMetrics VIA Terraform will fail *initially* because you cannot create metrics til they are emitted to Azure.  I am unaware of a way to add delays to Terraform until Azure receives the metrics, so instead I let the creation fail and rerun the terraform scripts later (usually after a few minutes), this way the infrastructure is still co-located.

* AKS API Servers may be public, this is because of rapidly changing IP addresses due to DHCP configs.  Code is still in-place to make the API Servers private again (./modules/aks/main.tf line 21-22).  You still need an appropriate Kubeconfig to utilize the API Servers, they just no longer have any IP whitelisting (which isn't good security anyway).
