import subprocess
import csv

# Define the path to the CSV file
csv_file_path = "withOutMFAOnly_12122024.csv"


# Define the PowerShell script
def run_powershell_command(command):
    """Runs a PowerShell command and returns the output."""
    result = subprocess.run(["powershell", "-Command", command], capture_output=True, text=True)
    if result.returncode == 0:
        return result.stdout.strip()
    else:
        print(f"Error: {result.stderr.strip()}")
        return None


# Step 1: Connect to MsolService
print("Connecting to Microsoft Online Service...")
connect_command = "Connect-MsolService"
connect_output = run_powershell_command(connect_command)

if connect_output is None:
    print("Failed to connect to Microsoft Online Service. Exiting.")
    exit()

print("Connected successfully!")

# Step 2: Read the CSV file and process each row
print("Processing CSV file...")
try:
    with open(csv_file_path, mode="r") as file:
        csv_reader = csv.reader(file)
        headers = next(csv_reader)  # Skip the header row

        # Ensure the CSV is formatted correctly
        if len(headers) < 1:
            print("Error: CSV file must have at least one column.")
            exit()

        for row in csv_reader:
            if row:  # Skip empty rows
                primary_key = row[1]  # Take the first column value as the primary key

                # Step 3: Execute Get-MsolUser for the primary key
                command = f"Get-MsolUser -UserPrincipalName {primary_key} | Select-Object UserPrincipalName, DisplayName, Department"
                output = run_powershell_command(command)

                # Print the result for each user
                if output:
                    print(f"Result for {primary_key}:\n{output}\n")
except FileNotFoundError:
    print(f"Error: The file '{csv_file_path}' does not exist. Please provide a valid path.")
except Exception as e:
    print(f"An error occurred: {e}")
