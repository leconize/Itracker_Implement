import psycopg2


class Database():

    def __init__(self, dbname, user, host, password):
        try:
            self.dbname = dbname
            self.user = user
            self.host = host
            self.password = password

            self.connection = psycopg2.connect("dbname='{}' user='{}' host='{}' password='{}'"
                                               .format(dbname, user, host, password))
            # cursor = self.connection.cursor()
            # cursor.execute("select * from session")
            # rows = cursor.fetchall()
            # for row in rows:
            #     print("   ", row[0])
            # cursor.close()
            self.connection.close()
        except:
            print("I am unable to connect to the database")