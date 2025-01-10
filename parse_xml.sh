#!/bin/bash

# Function to validate XML file
validate_xml() {
  local xml_file=$1

  if [ ! -f "$xml_file" ]; then
    echo "Error: XML file '$xml_file' not found."
    return 1
  fi

  declare -a tag_stack
  while IFS= read -r line; do
    tags=$(echo "$line" | grep -oP "<[^>]+>")

    for tag in $tags; do
      if [[ $tag == "</"* ]]; then
        closing_tag=${tag:2:-1}
        if [[ ${#tag_stack[@]} -eq 0 || ${tag_stack[-1]} != "$closing_tag" ]]; then
          echo "Error: Mismatched or extra closing tag '$tag' in XML file '$xml_file'."
          echo "Suggestion: Ensure every opening tag has a matching closing tag in the correct order."
          return 1
        fi
        unset tag_stack[-1]
      elif [[ $tag == "<"*"/>" ]]; then
        continue
      elif [[ $tag == "<"* ]]; then
        opening_tag=$(echo "$tag" | sed -E 's/<([^ >]+).*/\1/' | sed 's/>//')
        tag_stack+=("$opening_tag")
      fi
    done
  done < "$xml_file"

  if [[ ${#tag_stack[@]} -gt 0 ]]; then
    echo "Error: Unclosed tags detected in XML file '$xml_file'."
    echo "Suggestion: Add closing tags for the following: ${tag_stack[*]}."
    return 1
  fi

  echo "XML file '$xml_file' is well-formed."
  return 0
}

# Function to convert XML to JSON
xml_to_json() {
  local xml_file=$1
  local json_file=$2

  if ! validate_xml "$xml_file"; then
    echo "Cannot convert invalid XML file to JSON."
    return 1
  fi

  echo "{" > "$json_file"
  while IFS= read -r line; do
    # Extract key-value pairs using grep and sed
    key=$(echo "$line" | grep -oP "(?<=<)[a-zA-Z0-9_]+(?=>)" | head -n 1)
    value=$(echo "$line" | grep -oP "(?<=>)[^<]+(?=</)")

    # If both key and value are extracted, add them to JSON
    if [[ -n $key && -n $value ]]; then
      echo "  \"$key\": \"$value\"," >> "$json_file"
    fi
  done < "$xml_file"
  sed -i '$ s/,$//' "$json_file" # Remove trailing comma
  echo "}" >> "$json_file"

  echo "JSON file '$json_file' created successfully."
}

# Function to read JSON file
read_json() {
  local json_file=$1

  if [ ! -f "$json_file" ]; then
    echo "Error: JSON file '$json_file' not found."
    return 1
  fi

  echo "Contents of '$json_file':"
  cat "$json_file"
}

# Function to write to JSON file
write_to_json() {
  local json_file=$1

  if [ ! -f "$json_file" ]; then
    echo "Error: JSON file '$json_file' not found."
    return 1
  fi

  read -rp "Enter the key to add: " key
  read -rp "Enter the value for the key: " value

  # Add the new key-value pair before the closing '}'
  sed -i '$ s/}/,/' "$json_file"
  echo "  \"$key\": \"$value\"" >> "$json_file"
  echo "}" >> "$json_file"

  echo "Added '$key': '$value' to '$json_file'."
}

# Function to convert JSON back to XML
json_to_xml() {
  local json_file=$1
  local xml_file=$2

  if [ ! -f "$json_file" ]; then
    echo "Error: JSON file '$json_file' not found."
    return 1
  fi

  echo "<root>" > "$xml_file"
  while IFS= read -r line; do
    # Match key-value pairs using grep and sed
    key=$(echo "$line" | grep -oP '"\K[a-zA-Z0-9_]+(?=":)')
    value=$(echo "$line" | grep -oP ':\s*"\K[^"]+(?=")')

    # If both key and value are found, add them to the XML file
    if [[ -n $key && -n $value ]]; then
      echo "  <$key>$value</$key>" >> "$xml_file"
    fi
  done < "$json_file"
  echo "</root>" >> "$xml_file"

  echo "XML file '$xml_file' created successfully."
}

# Main menu
while true; do
  echo "Choose an option:"
  echo "1. Validate XML file"
  echo "2. Convert XML to JSON"
  echo "3. Read JSON file"
  echo "4. Write to JSON file"
  echo "5. Convert JSON back to XML"
  echo "6. Exit"
  read -rp "Enter your choice: " choice

  case $choice in
    1)
      read -rp "Enter the XML file path: " xml_file
      validate_xml "$xml_file"
      ;;
    2)
      read -rp "Enter the XML file path: " xml_file
      read -rp "Enter the output JSON file path: " json_file
      xml_to_json "$xml_file" "$json_file"
      ;;
    3)
      read -rp "Enter the JSON file path: " json_file
      read_json "$json_file"
      ;;
    4)
      read -rp "Enter the JSON file path: " json_file
      write_to_json "$json_file"
      ;;
    5)
      read -rp "Enter the JSON file path: " json_file
      read -rp "Enter the output XML file path: " xml_file
      json_to_xml "$json_file" "$xml_file"
      ;;
    6)
      echo "Exiting program."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac
done