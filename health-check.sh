origin=$(git remote get-url origin)

KEYSARRAY=()
URLSARRAY=()

urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"
while read -r line; do
  echo "  $line"
  IFS='=' read -ra TOKENS <<< "$line"
  KEYSARRAY+=("${TOKENS[0]}")
  URLSARRAY+=("${TOKENS[1]}")
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p logs

for (( index=0; index < ${#KEYSARRAY[@]}; index++ )); do
  key="${KEYSARRAY[index]}"
  url="${URLSARRAY[index]}"
  echo "  $key=$url"

  result="failed"
  final_url="$url"
  status="000"

  for i in 1 2 3 4; do
    # Follow redirects (-L), show final URL (-w %{url_effective}), capture status code
    response=$(curl -Ls -o /dev/null -w "%{http_code} %{url_effective}" "$url")
    status=$(echo "$response" | awk '{print $1}')
    final_url=$(echo "$response" | awk '{print $2}')

    if [[ "$status" == "200" || "$status" == "202" || "$status" == "301" || "$status" == "302" || "$status" == "307" ]]; then
      result="success"
      break
    fi
    sleep 5
  done

  dateTime=$(date +'%Y-%m-%d %H:%M')
  echo "    [$dateTime] $key: $result (status=$status, final_url=$final_url)"

  echo "$dateTime, $result, $status, $final_url" >> "logs/${key}_report.log"
  # Keep last 2000 lines
  echo "$(tail -2000 logs/${key}_report.log)" > "logs/${key}_report.log"

done

git config --global user.name 'Logan Foster'
git config --global user.email 'lrfoster03@outlook.com'
git add -A --force logs/
git commit -am '[Automated] Update Health Check Logs'
git push