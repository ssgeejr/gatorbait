def read_and_format_data(file_path):
    try:
        with open(file_path, 'r') as file:
            content = file.read()

        entries = content.strip().split('\n\n')  # Split entries on empty lines
        formatted_lines = []

        for entry in entries:
            lines = entry.strip().split('\n')
            formatted_line = '\t'.join(line.strip() for line in lines)
            formatted_lines.append(formatted_line)

        # Print all formatted lines
        for formatted_line in formatted_lines:
            print(formatted_line)

    except FileNotFoundError:
        print("The specified file does not exist.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Replace 'file_path.txt' with the actual path to your data file
file_path = 'data.dat'
read_and_format_data(file_path)
