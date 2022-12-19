#!/bin/bash

#####################################################
# Author: 		Navid Radkusha
# Date: 		16/12/2022
# Description: 	Move secrets from keyvault to another keyvault
####################################################

main() {
	parse_params "$@"
	check_params
	move-secrets
}

move-secrets() {
    # Get secrets from old keyvault 
	SECRETS+=($(az keyvault secret list --vault-name $oldkeyvault --query "[].id" -o tsv))

    # Loop over secrets
    for SECRET in "${SECRETS[@]}";
	do
	# get the secret name 
	SECRETNAME=$(echo "$SECRET" | sed 's|.*/||')
	# check if secret exist
	SECRET_CHECK=$(az keyvault secret list --vault-name $DESTINATION_KEYVAULT --query "[?name=='$SECRETNAME']" -o tsv)
	if [ -n "$SECRET_CHECK" ]
	then
		echo "A secret with name $SECRETNAME already exists in $newkeyvault"
	else
		echo "Copying $SECRETNAME to KeyVault: $newkeyvault"
		SECRET=$(az keyvault secret show --vault-name $oldkeyvault -n $SECRETNAME --query "value" -o tsv)
		az keyvault secret set --vault-name $newkeyvault -n $SECRETNAME --value "$SECRET" >/dev/null
	fi
    done
}

check_params() {
	# Check if newkeyvault is provided
	if [[ -z $newkeyvault ]]; then
		echo "New keyvault is required."
		exit 1
	fi

	# Check if oldkeyvault is provided
	if [[ -z $oldkeyvault ]]; then
		echo "Old keyvault is required."
		exit 1
	fi
}

parse_params() {
	
	# Check if parameters are passed
	if [[ $? -ne 0 ]]; then
		exit 1
	fi

	while getopts :n:o:h option
	do
		case $option in
			n) newkeyvault=$OPTARG ;;
			o) oldkeyvault=$OPTARG ;;
			h)
				echo "Usage: $(basename $0) -n <newkeyvault> -o <oldkeyvault>"
				echo "You have to be logged in to azure, use 'az login'"
				exit 0
				;;
			:)
				echo "Option -$OPTARG requires an argument" >&2
				exit 1
				;;
			*)
				echo "Invalid argument: -$OPTARG" >&2
				exit 1
				;;
		esac
	done
}

main "$@"; exit