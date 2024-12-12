import subprocess
import csv
import mysql.connector
from datetime import datetime
from Crocodile import Saturn

class Buddy:
    def __init__(self):
        self.batch_file = 'testMFAStatus.cmd'
        self.db_connection = None
        self.db_cursor = None

    def run_batch_file(self):
        """Execute the batch file and capture the output."""
        result = subprocess.run([self.batch_file], capture_output=True, text=True)
        if result.returncode != 0:
            print("Error running batch file:", result.stderr)
            exit(1)
        # The result output is expected to be the current date
        self.current_date = result.stdout.strip()
        print(f'DATE: {self.current_date}')
        self.filename = f'withOutMFAOnly_{self.current_date}.csv'
        print(f'FILENAME: {self.filename}')
        #return current_date

    def read_csv_and_insert_into_db(self):
        """Read the CSV file and insert its contents into MySQL database."""
        # Open CSV file
        try:
            with open(self.filename, mode='r', newline='') as file:
                csv_reader = csv.DictReader(file)
                self.db_cursor.execute("delete from gator where 1=1")
                self.db_connection.commit()
                insert_query = """
                     INSERT INTO gator (gatorid, displayname, email, department, isadmin, mfaenabled)
                     VALUES (%s, %s, %s, %s, %s, %s)
                 """
                loaded_records = 0
                for row in csv_reader:
                    data = (
                        self.current_date,
                        row['DisplayName'],
                        row['UserPrincipalName'],
                        row['Department'],
                        row['isAdmin'],
                        row['MFA Enabled']
                    )
                    self.db_cursor.execute(insert_query, data)
                    loaded_records += 1
                    if (loaded_records % 100) == 0:
                        self.db_connection.commit()
            self.db_connection.commit()
            print(f'Total records loaded: {loaded_records}')
        except mysql.connector.Error as err:
            print("Error inserting into database:", err)

    def connect_to_db(self):
        """Establish a connection to the MySQL database."""
        try:
            saturn = Saturn()

            self.db_connection = mysql.connector.connect(
                host=saturn.getServer(),         # Update with your MySQL server details
                user=saturn.getUsername(),              # Update with your MySQL username
                password=saturn.getPassword(),      # Update with your MySQL password
                database=saturn.getDB()
            )
            self.db_cursor = self.db_connection.cursor()
        except mysql.connector.Error as err:
            print("Error connecting to MySQL:", err)
            exit(1)

    def close_db_connection(self):
        """Close the database connection."""
        if self.db_cursor:
            self.db_cursor.close()
        if self.db_connection:
            self.db_connection.close()

    def close_file(self, file):
        """Close the file."""
        file.close()

    def process(self):
        """Main process for the Buddy class."""
        #current_date = self.run_batch_file()
        #csv_filename = f"{current_date}.csv"
        #print(f"Processing file: {csv_filename}")

        self.run_batch_file()
        self.connect_to_db()
        self.read_csv_and_insert_into_db()
        self.close_db_connection()

if __name__ == '__main__':
    buddy = Buddy()
    buddy.process()
    #buddy.run_batch_file()
