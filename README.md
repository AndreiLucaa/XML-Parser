# XML Reader and Writer Script

This script allows you to **read** and **write** data from/to XML files using XPath queries. It is a simple and flexible tool for working with XML files in a Linux/Unix environment.

## Features
- **Read XML Content**: Extract specific parts of an XML file using an XPath query.
- **Write to XML**: Add a new XML node with a value under a specified parent node.

---

## Prerequisites
1. **Bash**: The script runs in a Bash shell.
2. **`xmllint`**: A command-line XML tool for parsing and querying XML files. Ensure it is installed:
   ```bash
   sudo apt install libxml2-utils
  
3. **XML File**: Ensure the file you want to process is valid XML.


## Usage

### 1. Reading from an XML File

Use the read command to extract information from an XML file using an XPath query.

#### Syntax: 

	./parse_xml.sh read <xpath> <file1> [file2 ...]

#### Details:

	•	<xpath>: The XPath query to specify the data to retrieve.
	•	<file1> [file2 ...]: One or more XML files to read from.
 

#### Examples ( Get the name of the manager for the Engineering department ):
	  
     ./parse_xml.sh read "//department[@name='Engineering']/manager/name/text()" file1.xml
 

    
 #### Output: 
     John Smith

### 2. Writing to an XML File

Use the write command to add a new XML node with a value under a specified parent node.

Syntax: 

    ./parse_xml.sh write <parent_node> <new_node> <new_value> <file1> [file2 ...]

Details:

 	•	<parent_node>: The parent XML node where the new node will be added (e.g., <employees>).
	•	<new_node>: The tag for the new node to add (e.g., <employee>).
	•	<new_value>: The value or sub-content for the new node.
	•	<file1> [file2 ...]: One or more XML files to modify.

#### Examples( Add a new employee to the HR department ):
	./parse_xml.sh write "<employees>" "employee" "<name>Michael Green</name><position>Recruiter</position>" company.xml


### 3. Help

#### Run the script without arguments or with incorrect arguments to see the usage:
    ./parse_xml.sh
       
