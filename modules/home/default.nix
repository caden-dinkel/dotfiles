{ git, name, ... }: {
  imports = [
    ./home.nix
  ];
  myUsers.enable = true;
  myUsers.home.${name} = {
    enable = true;
    dev = {
      enable = true;
      git = {
        name = git.name;
        email = git.email;
      };
    };
  };
}
