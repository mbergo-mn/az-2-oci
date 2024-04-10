#!/bin/bash

# Set the OCI bucket name
OCI_BUCKET_NAME="Az2OCI"

# Set the Azure resource group
AZURE_RESOURCE_GROUP="$1"

# Login to Azure
az login

# List all vaults in the resource group
vaults=$(az backup vault list --resource-group $AZURE_RESOURCE_GROUP --query "[].name" -o tsv)

# Iterate through each vault
for vault in $vaults; do
    echo "Processing vault: $vault"

    # List all protected items in the vault
    protected_items=$(az backup item list --vault-name $vault --resource-group $AZURE_RESOURCE_GROUP --query "[].properties.friendlyName" -o tsv)

    # Iterate through each protected item (instance)
    for item in $protected_items; do
        echo "  Processing instance: $item"

        # List all recovery points (snapshots) for the instance
        recovery_points=$(az backup recoverypoint list --vault-name $vault --resource-group $AZURE_RESOURCE_GROUP --container-name $item --item-name $item --query "[].name" -o tsv)

        # Iterate through each recovery point
        for recovery_point in $recovery_points; do
            echo "    Processing recovery point: $recovery_point"

            # Export the snapshot to a file (assuming this functionality exists, you may need to adjust this part)
            # This is a placeholder command, as exporting snapshots is not directly supported by Azure CLI.
            # You may need to use a different method to export the snapshot, depending on your requirements.
            az backup recoverypoint export --vault-name $vault --resource-group $AZURE_RESOURCE_GROUP --container-name $item --item-name $item --name $recovery_point --file "$vault/$item/$recovery_point.tar"

            # Upload the exported snapshot to OCI bucket
            oci os object put --bucket-name $OCI_BUCKET_NAME --file "$vault/$item/$recovery_point.tar" --name "$vault/$item/$recovery_point.tar"

            # Clean up the exported file
            rm "$vault/$item/$recovery_point.tar"
        done
    done
done

echo "All snapshots have been exported and uploaded to OCI bucket: $OCI_BUCKET_NAME"
