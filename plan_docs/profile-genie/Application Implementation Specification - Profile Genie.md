# **New Application**

## **App Title**

Prof
ile Genie

## **Development Plan**

This proj
ect will follow an Agile development methodol
ogy, focusing on iterative delivery of the fe
atures outlined in the user story backlog. Th
e development will be organized into logical 
phases, starting with the core application in
frastructure and security, followed by the im
plementation of the automation engine and "Sc
out Agent" protocol, and culminating in the p
rimary application workflow and user experien
ce enhancements. The detailed, phased backlog
 is available in the "Detailed Development Pl
an: Profile Genie v1" document.

## **Descrip
tion**

### **Overview**

Profile Genie is a 
web application designed to automate the tedi
ous process of applying for user research stu
dies. It functions as a smart assistant that 
learns a user's professional and personal pro
file over time. It then leverages this stored
 profile to automatically fill out repetitive
 screening surveys on platforms like userinte
rviews.com.

A key innovation is the "Scout A
gent" protocol, which uses a disposable secon
dary account to perform reconnaissance on mul
ti-step questionnaires. The Scout Agent navig
ates the entire survey, gathers all the quest
ions, and presents only the unknown ones to t
he user. Once the user provides the new answe
rs, the system uses the user's primary accoun
t to fill and submit the application in a sin
gle, fast, and human-like pass.

The architec
ture prioritizes security, maintainability, a
nd robustness to create a trusted, reliable, 
and time-saving tool for user research partic
ipants.

### **Document Links**

* Architectu
re Document: Profile Genie v1  
* Detailed De
velopment Plan: Profile Genie v1

## **Requir
ements**

### **Features**

* \[x\] **User Ac
counts:** Secure user registration, login (JW
T-based), and logout.  
* \[x\] **Profile Man
agement:** A dedicated UI for users to create
, view, update, and delete their profile data
 (question/answer pairs).  
* \[x\] **Secure 
Credential Storage:** Encrypted storage (.NET
 Data Protection APIs) for third-party (Prima
ry and Scout) account credentials.  
* \[x\] 
**Scout Agent Protocol:** An automation workf
low to map multi-page surveys using a disposa
ble account to discover all questions.  
* \[
x\] **Intelligent Question Review:** A system
 to compare scouted questions against the use
r's profile and only prompt the user for answ
ers to unknown questions.  
* \[x\] **Primary
 Application Workflow:** An automation workfl
ow to log in with the user's primary account 
and fill out the entire survey using the comp
lete profile data.  
* \[x\] **Informative Da
shboard:** A central dashboard displaying pro
file completeness, recent activity, and sugge
sted studies.  
* \[x\] **Advanced Filtering:
** Tools for users to filter and sort availab
le studies by criteria like payout, keywords,
 and match score.  
* \[x\] **Bot Evasion:** 
Human-like automation techniques (random dela
ys, simulated typing, realistic browser finge
rprint) to minimize the risk of detection.  

* \[x\] **CAPTCHA Handling:** Graceful failur
e upon detecting a CAPTCHA, notifying the use
r with a screenshot to allow for manual inter
vention.  
* \[ \] **Interactive Fallback Mod
e (Stretch Goal):** A SignalR-based real-time
 mode for handling surveys where the Scout pr
otocol fails.

### **Test cases**

* Unit and
 integration tests will be written for all ba
ckend business logic, targeting a high code c
overage percentage.  
* End-to-end tests will
 be developed for the core user workflows, in
cluding registration, profile editing, and th
e complete scout-then-fill application proces
s.

### **Logging**

* Structured logging (e.
g., using Serilog) will be implemented across
 all services.  
* Logs will be separated by 
service and will capture key events, errors, 
and automation outcomes. In production, logs 
will be shipped to a centralized logging prov
ider.

### **Containerization: Docker**

* \[
x\] Each service (Backend API, Playwright Ser
vice) will have a dedicated Dockerfile for co
ntainerization.  
* \[x\] The database will r
un in a Docker container for local developmen
t consistency.

### **Containerization: Docke
r Compose**

* \[x\] A docker-compose.yml fil
e will be provided to orchestrate the entire 
application stack (UI, API, Automation Servic
e, Database) for simplified local development
 setup.

### **Swagger/OpenAPI**

* \[x\] The
 ASP.NET Core API and the Playwright Service 
will expose an OpenAPI (Swagger) specificatio
n for clear API documentation and testing.

#
## **Documentation**

* \[x\] A README.md fil
e will detail the project setup, configuratio
n, and how to run the application locally.  

* \[x\] Code will be documented with comments
, particularly for complex business logic and
 public-facing API methods.

### **Acceptance
 Criteria**

Acceptance for each feature is d
efined by the specific, testable criteria out
lined in the user stories within the "Detaile
d Development Plan: Profile Genie v1" documen
t. The project is considered complete when al
l stories are implemented and their respectiv
e acceptance criteria are met and validated.


## **Language**

C\#

## **Language Version*
*

.NET v9.0

\[x\] Include global.json? sdk:
 "9.0.0", rollForward: "latestFeature"

## **
Frameworks, Tools, Packages**

| Category | T
echnology / Package | Rationale |
| :---- | :
---- | :---- |
| **Orchestration** | .NET Asp
ire | Simplifies local development, service d
iscovery, and deployment orchestration for a 
multi-service architecture. |
| **Backend Fra
mework** | ASP.NET Core | High-performance, m
ature framework for building robust, cross-pl
atform APIs. |
| **Frontend Framework** | Bla
zor Server | Enables a rich, interactive UI w
ith C\#, reducing context switching and provi
ding a "desktop-like" feel suitable for a pow
er-user tool. |
| **Database** | PostgreSQL |
 Robust, open-source relational database with
 excellent support for JSONB, ideal for stori
ng flexible profile data. |
| **Data Access**
 | Entity Framework Core | Modern ORM that si
mplifies data access and provides a code-firs
t migrations workflow for schema management. 
|
| **Browser Automation** | Playwright | A m
odern, reliable, and powerful library for bro
wser automation that is well-supported and of
fers a rich feature set. |
| **Authentication
** | ASP.NET Core Identity | Provides a secur
e and battle-tested framework for managing us
er accounts, password hashing, and token gene
ration (JWTs). |
| **Real-time Fallback** | S
ignalR | Enables real-time, bi-directional co
mmunication needed for the "Interactive Loop 
Model" stretch goal. |

## **Project Structur
e/Package System**

The solution will be orga
nized as a service-oriented architecture mana
ged by a .NET Aspire AppHost project.

* **Pr
ofileGenie.AppHost**: The .NET Aspire project
 that orchestrates all other services.  
* **
ProfileGenie.Web**: The Blazor Server project
 containing all UI components and client-side
 logic.  
* **ProfileGenie.ApiService**: The 
main ASP.NET Core backend API. It handles all
 business logic, user identity, and database 
interactions.  
* **ProfileGenie.PlaywrightSe
rvice**: A minimal, standalone ASP.NET Core A
PI dedicated exclusively to running Playwrigh
t automation jobs.  
* **ProfileGenie.Data**:
 A class library containing the Entity Framew
ork DbContext and data models.  
* **ProfileG
enie.Shared**: A class library for shared DTO
s and contracts between the services.

## **G
itHub**

### **Repo**

https://github.com/nam
20485/ProfileGenie

### **Branch**

main

## 
**Deliverables**

1. A fully functional, cont
ainerized web application implementing all th
e features listed above.  
2. Complete source
 code hosted in the specified GitHub reposito
ry.  
3. Comprehensive documentation (README.
md) covering setup, configuration, and local 
deployment.  
4. Dockerfiles for each service
 and a Docker Compose file for easy local orc
hestration.  
5. An OpenAPI specification for
 all backend services.

