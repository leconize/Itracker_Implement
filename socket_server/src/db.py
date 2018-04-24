import psycopg2


class Database():

    def __init__(self, dbname, user, host, password):
        try:
            self.dbname = dbname
            self.user = user
            self.host = host
            self.password = password
            # cursor = self.connection.cursor()
            # cursor.execute("select * from session")
            # rows = cursor.fetchall()
            # for row in rows:
            #     print("   ", row[0])
            # cursor.close()
        except:
            print("I am unable to connect to the database")
    
    def createConnection(self):
        return psycopg2.connect("dbname='{}' user='{}' host='{}' password='{}'"
                                               .format(self.dbname, self.user, self.host, self.password))
