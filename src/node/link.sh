function expand_path {
  ruby -e 'puts File.expand_path(ARGV[0])' ${1}
}

function resolve_path {
  ruby -e 'puts File.symlink?(ARGV[0]) ? File.expand_path(ARGV[0]) : ARGV[0]' ${1}  
}

for fn in bin/*; do
  echo $fn
  abs=$(expand_path "${fn}")
  base=$(basename "${fn}")
  dst=$(expand_path "~/bin/${base}")
  echo "[ln] ${abs} -> ~/bin/${base}"
  ln -svf "${abs}" "${dst}"
done
