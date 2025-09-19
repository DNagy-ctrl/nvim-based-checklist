#!/bin/bash

TODO_FILE="$HOME/toDo.md"
current_line=1
total_lines=0
undo_stack=()
max_undo=10

# Create file if it doesn't exist
if [[ ! -f "$TODO_FILE" ]]; then
    touch "$TODO_FILE"
fi

# Save state for undo
save_state() {
    local backup_file="/tmp/todo_backup_$(date +%s)_$"
    cp "$TODO_FILE" "$backup_file"
    undo_stack+=("$backup_file")
    
    # Keep only last 10 states
    if [[ ${#undo_stack[@]} -gt $max_undo ]]; then
        rm -f "${undo_stack[0]}" 2>/dev/null
        undo_stack=("${undo_stack[@]:1}")
    fi
}

# Undo last change
undo_change() {
    if [[ ${#undo_stack[@]} -gt 0 ]]; then
        local last_state="${undo_stack[-1]}"
        if [[ -f "$last_state" ]]; then
            cp "$last_state" "$TODO_FILE"
            rm -f "$last_state"
            undo_stack=("${undo_stack[@]:0:${#undo_stack[@]}-1}")
            echo "Undone! ↶"
        else
            echo "Backup file not found!"
        fi
    else
        echo "Nothing to undo!"
    fi
    sleep 1
}

update_line_count() {
    if [[ -f "$TODO_FILE" ]]; then
        total_lines=$(wc -l < "$TODO_FILE" 2>/dev/null)
    else
        total_lines=0
    fi
    
    if [[ $total_lines -eq 0 ]]; then
        total_lines=1
    fi
    
    if [[ $current_line -gt $total_lines ]]; then
        current_line=$total_lines
    fi
    
    if [[ $current_line -lt 1 ]]; then
        current_line=1
    fi
}

display_file() {
    clear
    echo "📋 Todo Manager"
    echo "==============="
    echo "j/k: move up/down | a: add | m: toggle | r: edit | x: delete | u: undo | q: quit"
    echo "====================================================================="
    
    update_line_count
    
    if [[ $total_lines -eq 0 ]] || [[ ! -s "$TODO_FILE" ]]; then
        echo -e "\n📝 Empty todo list - press 'a' to add items"
        current_line=1
        return
    fi
    
    echo
    local line_num=1
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $line_num -eq $current_line ]]; then
            # Current line highlighting
            if [[ "$line" =~ ^-\ \[x\] ]]; then
                # Completed item - green background
                printf ">> \033[42;30m%2d: %s\033[0m\n" "$line_num" "$line"
            elif [[ "$line" =~ ^-\ \[\ \] ]]; then
                # Pending item - yellow background
                printf ">> \033[43;30m%2d: %s\033[0m\n" "$line_num" "$line"
            else
                # Regular item - white background
                printf ">> \033[47;30m%2d: %s\033[0m\n" "$line_num" "$line"
            fi
        elif [[ "$line" =~ ^-\ \[x\] ]]; then
            # Completed item - green text
            printf "   \033[32m%2d: %s\033[0m\n" "$line_num" "$line"
        elif [[ "$line" =~ ^-\ \[\ \] ]]; then
            # Pending item - yellow text
            printf "   \033[33m%2d: %s\033[0m\n" "$line_num" "$line"
        else
            # Regular line - normal
            printf "   %2d: %s\n" "$line_num" "$line"
        fi
        line_num=$((line_num + 1))
    done < "$TODO_FILE"
    
    echo -e "\nLine $current_line of $total_lines"
}

move_up() {
    if [[ $current_line -gt 1 ]]; then
        current_line=$((current_line - 1))
    fi
}

move_down() {
    update_line_count
    if [[ $current_line -lt $total_lines ]]; then
        current_line=$((current_line + 1))
    fi
}

add_item() {
    echo -n "Enter todo item: "
    read -r item
    if [[ -n "$item" ]]; then
        save_state
        echo "- [ ] $item" >> "$TODO_FILE"
        update_line_count
        current_line=$total_lines
        echo "Added: $item"
        sleep 1
    fi
}

toggle_item() {
    if [[ $total_lines -eq 0 ]]; then
        echo "No items to toggle!"
        sleep 1
        return
    fi
    
    save_state
    local line_content
    line_content=$(sed -n "${current_line}p" "$TODO_FILE")
    
    if [[ "$line_content" =~ ^-\ \[\ \] ]]; then
        sed -i "${current_line}s/^- \[ \]/- [x]/" "$TODO_FILE"
        echo "Marked as completed ✅"
    elif [[ "$line_content" =~ ^-\ \[x\] ]]; then
        sed -i "${current_line}s/^- \[x\]/- [ ]/" "$TODO_FILE"
        echo "Marked as pending ⏳"
    else
        sed -i "${current_line}s/^/- [ ] /" "$TODO_FILE"
        echo "Converted to todo item 📝"
    fi
    sleep 1
}

edit_item() {
    if [[ $total_lines -eq 0 ]]; then
        echo "No items to edit!"
        sleep 1
        return
    fi
    
    local line_content
    line_content=$(sed -n "${current_line}p" "$TODO_FILE")
    
    local current_text=""
    if [[ "$line_content" =~ ^-\ \[x\]\ (.*)$ ]]; then
        current_text="${BASH_REMATCH[1]}"
    elif [[ "$line_content" =~ ^-\ \[\ \]\ (.*)$ ]]; then
        current_text="${BASH_REMATCH[1]}"
    else
        current_text="$line_content"
    fi
    
    echo "Current: $current_text"
    echo -n "New text: "
    read -r -e -i "$current_text" new_text
    
    if [[ -n "$new_text" ]]; then
        save_state
        if [[ "$line_content" =~ ^-\ \[x\] ]]; then
            sed -i "${current_line}s/.*/- [x] $new_text/" "$TODO_FILE"
        elif [[ "$line_content" =~ ^-\ \[\ \] ]]; then
            sed -i "${current_line}s/.*/- [ ] $new_text/" "$TODO_FILE"
        else
            sed -i "${current_line}s/.*/$new_text/" "$TODO_FILE"
        fi
        echo "Updated! ✨"
    fi
    sleep 1
}

delete_item() {
    if [[ $total_lines -eq 0 ]]; then
        echo "No items to delete!"
        sleep 1
        return
    fi
    
    local line_content
    line_content=$(sed -n "${current_line}p" "$TODO_FILE")
    
    echo "Delete: $line_content"
    echo -n "Are you sure? [Y/n]: "
    read -r confirm
    
    if [[ -z "$confirm" ]] || [[ "$confirm" =~ ^[Yy] ]]; then
        save_state
        sed -i "${current_line}d" "$TODO_FILE"
        update_line_count
        
        if [[ $current_line -gt $total_lines ]] && [[ $total_lines -gt 0 ]]; then
            current_line=$total_lines
        elif [[ $total_lines -eq 0 ]]; then
            current_line=1
        fi
        
        echo "Deleted! 🗑️"
    else
        echo "Cancelled."
    fi
    sleep 1
}

# Main loop
while true; do
    display_file
    echo -n "Command: "
    read -r -n1 key
    echo
    
    case "$key" in
        j|J)
            move_down
            ;;
        k|K)
            move_up
            ;;
        a|A)
            add_item
            ;;
        m|M)
            toggle_item
            ;;
        r|R)
            edit_item
            ;;
        x|X)
            delete_item
            ;;
        u|U)
            undo_change
            ;;
        q|Q)
            # Clean up backup files
            for backup in "${undo_stack[@]}"; do
                rm -f "$backup" 2>/dev/null
            done
            echo "Goodbye! 👋"
            exit 0
            ;;
        *)
            echo "Unknown command: '$key' (j/k: move, a: add, m: toggle, r: edit, x: delete, u: undo, q: quit)"
            sleep 1
            ;;
    esac
done
