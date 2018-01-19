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

**3. Explore Rest APIs**

The app defines following CRUD APIs.

    GET /api/notes
    
    POST /api/notes
    
    GET /api/notes/{noteId}
    
    PUT /api/notes/{noteId}
    
    DELETE /api/notes/{noteId}

You can test them using postman or any other rest client such as `curl`.

```bash
curl -k http://localhost:8080/api/notes 
curl -k -H "Content-Type: application/json" -X POST -d '{"title":"My first note","content":"Spring Boot is awesome!"}' http://localhost:8080/api/notes 
curl -k http://localhost:8080/api/notes/1
```

**4. Access the H2 Web Console**

Open your web browser at the following address `http://localhost:8080/h2-console` and log on using as username `sa`, database `jdbc:h2:mem:DEMO`

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

Prerequisite : The [Ansible Service Broker](https://github.com/openshift/ansible-service-broker/) must be installed locally as this feature is not yet available online !

1a. Start MiniShift with the experimental feature, OCP >= v3.7.0 and the Ansible Service Broker addon

```bash
git clone https://github.com/sabre1041/cdk-minishift-utils.git
minishift addons install cdk-minishift-utils/addons/ansible-service-broker/

minishift config set openshift-version v3.7.0
MINISHIFT_ENABLE_EXPERIMENTAL=y minishift start --service-catalog
minishift addons apply ansible-service-broker
minishift addons enable ansible-service-broker
```

1b. Start MiniShift with the experimental feature, OCP >= v3.7.0 and install Ansible Service Broker

```bash
minishift config set openshift-version v3.7.0
minishift config set image-caching true
MINISHIFT_ENABLE_EXPERIMENTAL=y minishift start --service-catalog
oc login -u system:admin        
oc adm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin

oc new-project ansible-service-broker
curl -s https://raw.githubusercontent.com/openshift/ansible-service-broker/master/templates/simple-broker-template.yaml | oc process -n "ansible-service-broker" -f - | oc create -f -
```

2. Check if the Service Catalog contains APB services

The process to download the repository of the catalog and deploy it locally could take time !

```bash
oc get clusterserviceclasses --all-namespaces -o custom-columns=NAME:.metadata.name,DISPLAYNAME:spec.externalMetadata.displayName | grep APB
```

3. Create a new namespace to host the project

```bash
oc new-project demo-spring-db
```

4. Deploy the MySQL Service within the namespace created

```bash
oc create -f openshift/mysql_serviceinstance.yml
```

5. Create a new app on the cloud platform

```bash
oc new-app -f openshift/spring-boot-db-notes_template.yml
```

6. Start the build

```bash
oc start-build spring-boot-db-notes-s2i --from-dir=. --follow
```

7. Bind the service to a secret

```bash
oc create -f openshift/mysql-secret_servicebinding.yml
```

8. Mount the secret within the dc

```bash
oc env --from=secret/spring-boot-notes-mysql-binding dc/spring-boot-db-notes
```

9. Test the service

```bash
export HOST=$(oc get route/spring-boot-db-notes -o jsonpath='{.spec.host}')
curl -k $HOST/api/notes 
curl -k -H "Content-Type: application/json" -X POST -d '{"title":"My first note","content":"Spring Boot is awesome!"}' $HOST/api/notes 
curl -k $HOST/api/notes/1
```
