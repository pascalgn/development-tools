#!/bin/sh
for context in $(kubectl config get-contexts -o name); do
    echo "alias kubectl-${context}='kubectl --context=${context}'"
done
echo "# Add the following line to your ${HOME}/.profile (or similar) file:"
echo "# eval \"\$($0)\""
