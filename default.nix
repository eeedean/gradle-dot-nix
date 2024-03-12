{ pkgs
, src
, gradle-fetcher-src
}:
let
    gradle-deps-json = pkgs.stdenv.mkDerivation {
        name = builtins.substring 11 32 ./gradle/verification-metadata.xml;
        src = src;
        buildInputs = [ pkgs.python3 ];
        buildPhase = ''
            python3 ${gradle-fetcher-src}/gradle-metadata-to-json.py ./gradle/verification-metadata.xml $out
        '';
    };

    gradle-deps-nix = builtins.fromJSON (builtins.readFile gradle-deps-json);

    conversion-function = unique-dependency:
    if unique-dependency.is_added_pom_file == "true" then
        {
                            name = unique-dependency.artifact_dir+"/"+unique-dependency.artifact_name;
                            path = "${pkgs.writeText unique-dependency.artifact_name ''
                             <project xmlns="http://maven.apache.org/POM/4.0.0"
                                      xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                                      http://maven.apache.org/xsd/maven-4.0.0.xsd"
                                      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                               <!-- This module was also published with a richer model, Gradle metadata,  -->
                               <!-- which should be used instead. Do not delete the following line which  -->
                               <!-- is to indicate to Gradle or any Gradle module metadata file consumer  -->
                               <!-- that they should prefer consuming it instead. -->
                               <!-- do_not_remove: published-with-gradle-metadata -->
                               <modelVersion>4.0.0</modelVersion>
                               <groupId>${unique-dependency.group}</groupId>
                               <artifactId>${unique-dependency.name}</artifactId>
                               <version>${unique-dependency.version}</version>
                             </project>
                           ''}";
        }
    else if unique-dependency.has_module_file == "true" then
        {
                            name = unique-dependency.artifact_dir+"/"+unique-dependency.artifact_name;
                            path = "${pkgs.stdenv.mkDerivation {
            name = unique-dependency.artifact_name;
            src = ./.;
            nativeBuildInputs = [ pkgs.python3 pkgs.python3Packages.requests  ];
            installPhase = ''
                python3 ${gradle-fetcher-src}/fetch-gradle-dependency.py $out True ${unique-dependency.name} ${unique-dependency.group} ${unique-dependency.version} ${unique-dependency.artifact_name} ${unique-dependency.artifact_dir} ${unique-dependency.module_file.artifact_name}
            '';
            outputHashAlgo = "sha256";
            outputHash = unique-dependency.sha_256;
        }}";
        }
    else
        {
                            name = unique-dependency.artifact_dir+"/"+unique-dependency.artifact_name;
                            path = "${pkgs.stdenv.mkDerivation {
            name = unique-dependency.artifact_name;
            src = ./.;
            nativeBuildInputs = [ pkgs.python3 pkgs.python3Packages.requests ];
            installPhase = ''
                python3 ${gradle-fetcher-src}/fetch-gradle-dependency.py $out False ${unique-dependency.name} ${unique-dependency.group} ${unique-dependency.version} ${unique-dependency.artifact_name} ${unique-dependency.artifact_dir}
            '';
            outputHashAlgo = "sha256";
            outputHash = unique-dependency.sha_256;
        }}";
        }
    ;
in
    pkgs.linkFarm "maven-repo" (map conversion-function gradle-deps-nix.components)