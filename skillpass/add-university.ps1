# PowerShell script to add a university to the SkillPass contract
# Make sure you have the Sui CLI installed and configured

# Contract configuration
$PACKAGE_ID = "0xf1cb82954194f281b4bcddee3b8922b81322cd742d2ab23d169dfaf11883c736"
$REGISTRY_ID = "0x6c0bab54d2c4ba3caba62063cb7e972370e60deb9dbbe2fd46f825897bde0bdd"
$UNIVERSITY_ADDRESS = "0xc9b77d442570dafd4737da69ad2d3eadd36eb5eca8ecd021037979b117c35e2d"

Write-Host "Adding university $UNIVERSITY_ADDRESS to SkillPass contract..."
Write-Host "Package ID: $PACKAGE_ID"
Write-Host "Registry ID: $REGISTRY_ID"

# Call the add_university function
sui client call --package $PACKAGE_ID --module certificate_registry --function add_university --args $REGISTRY_ID $UNIVERSITY_ADDRESS

Write-Host "University added successfully!"