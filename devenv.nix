{ pkgs, inputs, ... }:

{
  packages = [
    pkgs.git
    pkgs.sentencepiece
    (inputs.llama-cpp.packages.${pkgs.system}.default.overrideAttrs
      (oldAttrs: rec {
        NIX_CFLAGS_COMPILE = "-march=native -mtune=native";
        cmakeFlags = oldAttrs.cmakeFlags ++ (if pkgs.stdenv.isDarwin then [
          "-DLLAMA_METAL=ON"
        ] else [
          "-DLLAMA_AVX512=ON"
          "-DLLAMA_BLAS=1"
          "-DLLAMA_BLAS_VENDOR=OpenBLAS"
        ]);
        buildInputs = oldAttrs.buildInputs ++
          (if pkgs.stdenv.isLinux then [
            pkgs.openblas
          ] else [ ]) ++
          [
            pkgs.pkgconfig
          ];
      }))
  ];

  scripts.llama-to-pt-all.exec = ''
    convert.py models/7B/
    convert.py models/13B/
    convert.py models/30B/
    convert.py models/65B/
  '';

  scripts.llama-quantize-all.exec = ''
    for model in $(find -L models -iname "*f16.bin*"|sort); do
      quantize $model ''${model/f16/q4_0} 2
    done
    for model in $(find -L models -iname "*f32.bin*"|sort); do
      quantize $model ''${model/f32/q4_0} 2
    done
  '';

  scripts.loop-prompt.exec = ''
    while true; do 
      reset; llama -m models/65B/ggml-model-q4_0.bin -n 256 -p "$1" --color 2> /dev/null && echo "..." && sleep 30 && reset
    done
  '';

  languages.python = {
    enable = true;
    package = (pkgs.python310.withPackages
      (ps: with ps; [
        torch
        numpy
        sentencepiece
        # checkpoint transformation
        accelerate
        transformers
        protobuf
        # wizard
        fire
      ]));
    venv.enable = true;
  };

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";

  # See full reference at https://devenv.sh/reference/options/
}
