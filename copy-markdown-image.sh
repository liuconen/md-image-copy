#!/usr/bin/env bash

# 生成图片文件名
# $1: 图片链接
# $2: 存放文件夹
function generate_img_file_name() {
  local img_url="$1"
  local save_dir="$2"

  local file_name
  file_name=$(echo "$img_url" | grep -oP "\w+\.(jpe?g|png|gif)")
  [ "$file_name" == "" ] && file_name="$RANDOM.jpg"
  while [ -f "$save_dir/$file_name" ]; do
    file_name="$RANDOM.jpg"
  done
  echo "$file_name"
}

function main() {
  local md_file="$1"
  assets_dir="$(dirname "$md_file")/$(basename "$md_file" ".md").assets"
  # grep结果保存为数组
  mapfile -t results < <(grep -n -oP "\!\[[^\[\]]+\]\(https?:\/\/[^\(\)]+\)" "$md_file")
  if ((${#results[@]} > 0)); then
    [ -d "$assets_dir" ] || mkdir "$assets_dir"
  else
    exit 0
  fi

  for i in "${results[@]}"; do
    local number=${i%%:*}
    url=$(echo "$i" | grep -oP "(?<=\().+(?=\))")
    image_file="$assets_dir/$(generate_img_file_name "$url" "$assets_dir")"
    curl -L -o "$image_file" "$url"
    file_size=$(wc "$image_file" | awk '{print $3}')

    # 如果文件尺寸过小，认为下载失败
    if (("$file_size" < 10000)); then
      echo "下载失败"
      exit 0
    fi

    # 更改md文件中图片引用为本地下载的文件
    image_file=$(printf '%s\n' "$image_file" | sed -e 's/[\/&]/\\&/g')
    sed -i -r "$number""s/\(.+\)/($image_file)/g" "$md_file"
  done
}

main "$1"