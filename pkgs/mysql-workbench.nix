{ pkgs, ... }:

let
  orig = pkgs.mysql-workbench;
in
pkgs.runCommand "mysql-workbench-${orig.version}" {
  pname = "mysql-workbench";
  version = orig.version;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  meta = orig.meta;
} ''
  mkdir -p $out
  cp -rs ${orig}/* $out/
  chmod -R u+w $out
  rm $out/lib/mysql-workbench/modules/wb_server_management.py
  # Substitui a importação do módulo 'pipes' (removido no Python 3.13+) por 'shlex as pipes'
  sed "s/import pipes/import shlex as pipes/g" ${orig}/lib/mysql-workbench/modules/wb_server_management.py > $out/lib/mysql-workbench/modules/wb_server_management.py

  rm -rf $out/bin
  mkdir -p $out/bin
  makeWrapper ${orig}/bin/mysql-workbench-bin $out/bin/mysql-workbench \
    --set MWB_BASE_DIR "$out" \
    --set MWB_DATA_DIR "$out/share/mysql-workbench" \
    --set MWB_MODULE_DIR "$out/lib/mysql-workbench/modules" \
    --set MWB_LIBRARY_DIR "$out/share/mysql-workbench/libraries" \
    --set MWB_PLUGIN_DIR "$out/lib/mysql-workbench/plugins" \
    --prefix LD_LIBRARY_PATH : "$out/lib/mysql-workbench:$out/lib/mysql-workbench/plugins" \
    --prefix PYTHONPATH : "$out/lib/mysql-workbench/modules" \
    --prefix PATH : "${pkgs.python3}/bin" \
    --prefix PROJSO : "${pkgs.proj}/lib/libproj.so" \
    --set GDK_BACKEND "x11"
''
