# Issue: Storage Account resource is not declarative

I would expect the following sequences of operations to have the same outcome:

a. Sequence A
  1. Deploy a Bicep template with a storage account without `networkAcls` ([`without_acl.bicep`](./without_acl.bicep))

b. Sequence B
  1. Deploy a Bicep template with a storage account without `networkAcls` ([`without_acl.bicep`](./without_acl.bicep))
  2. Deploy a Bicep template with a storage account **with** `networkAcls` ([`with_acl.bicep`](./with_acl.bicep))
  3. Deploy a Bicep template with a storage account without `networkAcls` ([`without_acl.bicep`](./without_acl.bicep))

What actually happens, is that step 3 in Sequence B has no effect, and the state after step 2 and step 3 is identical.

To illustrate this, the `./run.sh` script in this repo can be used, which runs
Sequence B, and exports the state of the storage account after each step to
[`storage_account-step1.json`](./storage_account-step1.json),
[`storage_account-step2.json`](./storage_account-step2.json),
[`storage_account-step3.json`](./storage_account-step3.json).

And as can be seen from the file digest, the state after step 2 and step 3 is identical:

```console
$ md5sum storage_account-step*.json
310001f376b404b5b2fa930ace24bdb1  storage_account-step1.json
9b09a8e62a6e8772f592dc51a96b66e3  storage_account-step2.json
9b09a8e62a6e8772f592dc51a96b66e3  storage_account-step3.json
```

NOTE: All deploys use `--mode Complete` and `targetScope = 'resourceGroup'`

## Basis for expectation

The reasons I would expect Sequence A and Sequence B to have the same effect is because:

1. Bicep is marketed as "declarative language for describing and deploying Azure
   resources" [[ref](https://github.com/Azure/bicep)], so my expectation is that
   the Bicep template declares the state that resources should be in, and that
   deploying in complete mode should update actual resources to match the
   declared state.

2. Bicep also purports to deliver repeatable results
   [[ref](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep)]
   which is explained as follow:
    > Repeatedly deploy your infrastructure throughout the development lifecycle
    > and have confidence your resources are deployed in a consistent manner.
    > Bicep files are idempotent, which means you can deploy the same file many
    > times and get the same resource types in the same state. You can develop one
    > file that represents the desired state, rather than developing lots of
    > separate files to represent updates.

    Given this, I would expect the same Bicep template to produce the same
    result, which as this issue demonstrates, is not the case.

3. Bicep is marketed as "desired state configuration (DSC) which makes it easy
   to manage IT and development infrastructure as code" (IaC)
   [[ref](https://learn.microsoft.com/en-us/azure/developer/terraform/comparing-terraform-and-bicep?tabs=comparing-bicep-terraform-integration-features)].
   If Bicep treats the actual state of the resource as the desired state instead
   of the state defined in the Bicep template, then it is not clear how this is
   facilitating IaC.

Of course my expectation may be wrong, but in that case I think the
documentation should be updated to clearly indicate what is meant by
declarative, IaC and DSC if it is not in line with this expectation.


