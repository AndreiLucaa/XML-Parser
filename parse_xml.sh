#!/bin/bash


read_xml() {
    local file="$1"
    local xpath="$2"

    if [[ -f "$file" ]]; then
        echo "----------------------------------------"
        echo "Reading from file: $file"
        echo "XPath Query: $xpath"
        echo "----------------------------------------"

        
        result=$(xmllint --xpath "$xpath" "$file" 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            echo "Results found:"
            echo "----------------------------------------"
            echo "$result"
            echo "----------------------------------------"
        else
            echo "No results found for XPath '$xpath' in file '$file'."
        fi
        echo
    else
        echo "Error: File not found: $file"
    fi
}


write_xml() {
    local file="$1"
    local parent_node="$2"
    local new_node="$3"
    local new_value="$4"

    echo "----------------------------------------"
    echo "File: $file"
    echo "Parent Node to Modify: $parent_node"
    echo "New Node to Add: <$new_node>"
    echo "Value of New Node: $new_value"
    echo "----------------------------------------"

    if [[ -f "$file" ]]; then
        temp_file=$(mktemp)
        awk -v parent="$parent_node" -v node="$new_node" -v value="$new_value" '
            BEGIN { added = 0 }
            {
                print $0
                if ($0 ~ parent && added == 0) {
                    print "  <" node ">" value "</" node ">"
                    added = 1
                }
            }
        ' "$file" > "$temp_file"

        mv "$temp_file" "$file"
        echo "Updated $file successfully!"
    else
        echo "Error: File not found: $file"
    fi
}


if [[ "$1" == "read" ]]; then
    xpath="$2"
    shift 2
    for file in "$@"; do
        read_xml "$file" "$xpath"
    done
elif [[ "$1" == "write" ]]; then
    parent_node="$2"
    new_node="$3"
    new_value="$4"
    shift 4
    for file in "$@"; do
        write_xml "$file" "$parent_node" "$new_node" "$new_value"
    done
else
    echo "Usage:"
    echo "----------------------------------------"
    echo "  To read XML:"
    echo "      $0 read <xpath> <file1> [file2 ...]"
    echo
    echo "  To write to XML:"
    echo "      $0 write <parent_node> <new_node> <new_value> <file1> [file2 ...]"
    echo "----------------------------------------"
fi