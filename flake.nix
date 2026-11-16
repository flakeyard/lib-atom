{
  # No inputs (FY-0040): every function takes what it needs, such as lib of
  # the consumer's nixpkgs, as arguments.
  outputs =
    _:
    let
      # The root of the repository; nix/ reaches it as the argument root
      # (FY-0039).
      root = ./.;
    in
    {
      lib = import ./nix { inherit root; };
    };
}
