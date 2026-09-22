{
  users.groups.deploy = { };
  users.users.deploy = {
    description = "Deployment User for deploy-rs";
    group = "deploy";
    createHome = false;
  };
}
