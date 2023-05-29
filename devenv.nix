{ pkgs, inputs, ... }:

{
  packages = [
    pkgs.git
    (inputs.llama-cpp.packages.${pkgs.system}.default.overrideAttrs
      (oldAttrs: rec {
        NIX_CFLAGS_COMPILE = "-march=native -mtune=native";
        cmakeFlags = oldAttrs.cmakeFlags ++ [
          "-DLLAMA_AVX512=ON"
        ];
      }))
    pkgs.sentencepiece
  ];

  scripts.llama-to-pt-all.exec = ''
    convert.py models/7B/ 1
    convert.py models/13B/ 1
    convert.py models/30B/ 1
    convert.py models/65B/ 1
  '';

  scripts.llama-quantize-all.exec = ''
    for model in $(find -L models -iname "*f16.bin*"|sort); do
      quantize $model ''${model/f16/q4_0} 2
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
      ]));
  };

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";

  # See full reference at https://devenv.sh/reference/options/
}
