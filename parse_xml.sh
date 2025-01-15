#!/bin/bash

# Funcție pentru validarea unui fișier XML
validate_xml() {
  local xml_file=$1 # Salvează numele fișierului XML ca argument

  if [ ! -f "$xml_file" ]; then # Verifică dacă fișierul XML există
    echo "Eroare: Fișierul XML '$xml_file' nu a fost găsit." # Afișează un mesaj de eroare dacă fișierul lipsește
    return 1 # Returnează un cod de eroare
  fi

  declare -a tag_stack # Creează un array pentru a stoca tagurile deschise
  while IFS= read -r line; do # Citește fișierul linie cu linie
    tags=$(echo "$line" | grep -oP "<[^>]+>") # Extrage toate tagurile din linie

    for tag in $tags; do # Iterează prin fiecare tag
      if [[ $tag == "</"* ]]; then # Verifică dacă este un tag de închidere
        closing_tag=${tag:2:-1} # Extrage numele tagului de închidere
        if [[ ${#tag_stack[@]} -eq 0 || ${tag_stack[-1]} != "$closing_tag" ]]; then
          # Verifică dacă există o nepotrivire între tagul de închidere și cel de deschidere
          echo "Eroare: Tag de închidere nepotrivit sau în plus '$tag' în fișierul XML '$xml_file'."
          return 1 # Returnează eroare
        fi
        unset tag_stack[-1] # Scoate ultimul tag din stack
      elif [[ $tag == "<"*"/>" ]]; then
        continue # Ignoră tagurile care se închid singure
      elif [[ $tag == "<"* ]]; then
        opening_tag=$(echo "$tag" | sed -E 's/<([^ >]+).*/\1/' | sed 's/>//') # Extrage numele tagului de deschidere
        tag_stack+=("$opening_tag") # Adaugă tagul de deschidere în stack
      fi
    done
  done < "$xml_file"

  if [[ ${#tag_stack[@]} -gt 0 ]]; then # Verifică dacă există taguri neînchise
    echo "Eroare: Taguri neînchise detectate în fișierul XML '$xml_file'."
    return 1
  fi

  echo "Fișierul XML '$xml_file' este bine formatat." # Mesaj de succes
  return 0
}

# Funcție pentru conversia unui fișier XML în JSON
xml_to_json() {
  local xml_file=$1 # Calea fișierului XML de intrare
  local json_file=$2 # Calea fișierului JSON de ieșire

  if ! validate_xml "$xml_file"; then # Validează fișierul XML înainte de conversie
    echo "Nu se poate converti un fișier XML invalid în JSON."
    return 1
  fi

  echo "{" > "$json_file" # Inițializează JSON-ul cu o acoladă de deschidere
  while IFS= read -r line; do # Citește fiecare linie din fișierul XML
    key=$(echo "$line" | grep -oP "(?<=<)[a-zA-Z0-9_]+(?=>)" | head -n 1) # Extrage cheia (tagul)
    value=$(echo "$line" | grep -oP "(?<=>)[^<]+(?=</)") # Extrage valoarea dintre taguri

    if [[ -n $key && -n $value ]]; then # Dacă cheia și valoarea sunt valide
      echo "  \"$key\": \"$value\"," >> "$json_file" # Adaugă perechea cheie-valoare în JSON
    fi
  done < "$xml_file"
  sed -i '$ s/,$//' "$json_file" # Elimină ultima virgulă din JSON
  echo "}" >> "$json_file" # Adaugă acolada de închidere

  echo "Fișierul JSON '$json_file' a fost creat cu succes."
}

# Funcție pentru citirea unui fișier JSON
read_json() {
  local json_file=$1 # Calea fișierului JSON

  if [ ! -f "$json_file" ]; then # Verifică dacă fișierul JSON există
    echo "Eroare: Fișierul JSON '$json_file' nu a fost găsit."
    return 1
  fi

  echo "Conținutul fișierului '$json_file':" # Afișează conținutul fișierului
  cat "$json_file" # Citește și afișează conținutul JSON
}

# Funcție pentru adăugarea unei perechi cheie-valoare într-un fișier JSON
write_to_json() {
  local json_file=$1 # Calea fișierului JSON

  if [ ! -f "$json_file" ]; then # Verifică dacă fișierul JSON există
    echo "Eroare: Fișierul JSON '$json_file' nu a fost găsit."
    return 1
  fi

  read -rp "Introdu cheia de adăugat: " key # Solicită cheia de la utilizator
  read -rp "Introdu valoarea pentru cheie: " value # Solicită valoarea

  sed -i '$ s/}/,/' "$json_file" # Pregătește fișierul pentru adăugarea unei noi perechi
  echo "  \"$key\": \"$value\"" >> "$json_file" # Adaugă noua pereche cheie-valoare
  echo "}" >> "$json_file" # Închide JSON-ul

  echo "Perechea '$key': '$value' a fost adăugată în '$json_file'."
}

# Funcție pentru conversia JSON în XML
json_to_xml() {
  local json_file=$1 # Calea fișierului JSON
  local xml_file=$2 # Calea fișierului XML

  if [ ! -f "$json_file" ]; then # Verifică dacă fișierul JSON există
    echo "Eroare: Fișierul JSON '$json_file' nu a fost găsit."
    return 1
  fi

  echo "<root>" > "$xml_file" # Inițializează XML-ul cu un tag root
  while IFS= read -r line; do # Citește fiecare linie din fișierul JSON
    key=$(echo "$line" | grep -oP '"\K[a-zA-Z0-9_]+(?=":)') # Extrage cheia
    value=$(echo "$line" | grep -oP ':\s*"\K[^"]+(?=")') # Extrage valoarea

    if [[ -n $key && -n $value ]]; then # Dacă cheia și valoarea sunt valide
      echo "  <$key>$value</$key>" >> "$xml_file" # Adaugă perechea cheie-valoare în XML
    fi
  done < "$json_file"
  echo "</root>" >> "$xml_file" # Închide tagul root

  echo "Fișierul XML '$xml_file' a fost creat cu succes."
}

# Meniul principal
while true; do # Bucla principală a programului
  echo "Alege o opțiune:" # Afișează opțiunile disponibile
  echo "1. Validează fișierul XML"
  echo "2. Convertește XML în JSON"
  echo "3. Citește fișier JSON"
  echo "4. Scrie în fișier JSON"
  echo "5. Convertește JSON în XML"
  echo "6. Ieșire"
  read -rp "Introdu opțiunea ta: " choice # Citește alegerea utilizatorului

  case $choice in # Gestionează alegerea utilizatorului
    1)
      read -rp "Introdu calea fișierului XML: " xml_file
      validate_xml "$xml_file" # Validează fișierul XML
      ;;
    2)
      read -rp "Introdu calea fișierului XML: " xml_file
      read -rp "Introdu calea fișierului JSON de ieșire: " json_file
      xml_to_json "$xml_file" "$json_file" # Convertește XML în JSON
      ;;
    3)
      read -rp "Introdu calea fișierului JSON: " json_file
      read_json "$json_file" # Citește fișierul JSON
      ;;
    4)
      read -rp "Introdu calea fișierului JSON: " json_file
      write_to_json "$json_file" # Scrie în JSON
      ;;
    5)
      read -rp "Introdu calea fișierului JSON: " json_file
      read -rp "Introdu calea fișierului XML de ieșire: " xml_file
      json_to_xml "$json_file" "$xml_file" # Convertește JSON
      ;;
   6)
      echo "Iesire din program..."
      exit 0
      ;;
    *)
      echo "Alegere invalida."
      ;;
  esac
done