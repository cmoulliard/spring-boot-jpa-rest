# Spring Boot, JPA, Hibernate Rest API Tutorial

Build Restful CRUD API for a simple Note-Taking application using Spring Boot, Database (H2, MySQL), JPA and Hibernate.

## Requirements

1. Java - 1.8.x

2. Maven - 3.x.x

## Steps to Setup

**1. Clone the application**

```bash
git clone https://github.com/cmoulliard/spring-boot-jpa-rest.git
```
**2. Build and run the app using maven**

You can run the app using the `spring-boot maven plugin`

```bash
mvn clean spring-boot:run -Dspring.profiles.active=local -Ph2
```

The app will start running at <http://localhost:8080>.

## Explore Rest APIs

The app defines following CRUD APIs.

    GET /api/notes
    
    POST /api/notes
    
    GET /api/notes/{noteId}
    
    PUT /api/notes/{noteId}
    
    DELETE /api/notes/{noteId}

You can test them using postman or any other rest client.

## Deploy it on CloudFoundry

1. Create first a MySQL service

```bash
cf create-service cleardb spark mysql-notes-db 
```

2. Deploy the Spring boot application without launching it

```bash
cf push --no-start  
```

3. Bind the service and start the application

```bash
cf bs sb-db-rest mysql-notes-db
```

4. Start the application

```bash
cf start sb-db-rest
```

5. Test the service

```bash
curl -k https://sb-db-rest.cfapps.io/api/notes 
curl -k -H "Content-Type: application/json" -X POST -d '{"title":"My first note","content":"Spring Boot is awesome!"}' https://sb-db-rest.cfapps.io/api/notes 
curl -k https://sb-db-rest.cfapps.io/api/notes/1
```

## Deploy it on OpenShift
