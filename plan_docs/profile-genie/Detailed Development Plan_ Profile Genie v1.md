# **Detailed Development Plan: Profile Genie**

### **1\. Development Approach**

This project will be guided by the principles of **Agile development**, focusing on iterative progress, continuous feedback, and the flexible delivery of value. The core challenge of this project lies in the unpredictable nature of web automation; target websites can change, and new obstacles can arise without notice. An agile approach is therefore essential, as it allows us to adapt to these challenges in real-time. While not constrained by rigid sprint timeboxes, development will be organized around a prioritized product backlog. Work will be pulled from the top of the backlog, ensuring that the most critical, value-driving features are built first.

Regular ceremonies will keep the project on track:

* **Backlog Grooming:** The product backlog will be treated as a living document, with regular sessions to refine user stories, add detail, and re-prioritize based on new learnings.  
* **Demonstrations:** At the end of each major feature implementation, the work will be demonstrated to ensure it meets the requirements and provides a good user experience.  
* **Retrospectives:** The team will regularly reflect on the development process itself, identifying what's working well and what can be improved to increase efficiency and quality.

### **2\. Product Backlog**

This backlog represents the complete set of features and capabilities required to build Profile Genie. The user stories are prioritized to build the application from the ground up, starting with a secure foundation and progressively adding layers of automation, intelligence, and user-facing polish.

### **Feature: Core User & Profile Management**

* **Goal:** Establish the foundational security and data management capabilities of the application. This feature is the bedrock of the entire system. Without a secure and reliable way to manage user identities and the data that powers the automation, no other feature can function correctly.

**Story PG-01: User Registration**

* **As a** new user,  
* **I want to** create a secure account using my email and a password,  
* **So that** I can access the application and save my personal data.  
* **Acceptance Criteria:**  
  1. The UI must have a "Register" page with fields for email and password, including password confirmation.  
  2. The backend must validate that the email is in a valid format and is not already in use.  
  3. The password must meet minimum strength requirements (e.g., 8+ characters, including uppercase, lowercase, numbers, and symbols).  
  4. Passwords must be securely hashed and salted using the default PBKDF2 algorithm provided by ASP.NET Core Identity.  
  5. Upon successful registration, the user is redirected to the login page with a success message.  
  6. (Future Enhancement): An email confirmation flow will be considered to verify user emails.

**Story PG-02: User Login**

* **As a** registered user,  
* **I want to** log into the application with my email and password,  
* **So that** I can access my dashboard and saved profile.  
* **Acceptance Criteria:**  
  1. The UI must have a "Login" page.  
  2. The backend must validate the provided credentials against the hashed password.  
  3. Upon successful login, the backend must generate and return a signed, short-lived JWT (e.g., 1-hour expiry). A long-lived refresh token will also be issued and stored securely by the client to enable seamless session renewal.  
  4. The Blazor client must securely store the tokens and include the JWT in the authorization header of all subsequent API requests.  
  5. The system must implement rate limiting on the login endpoint (e.g., max 5 attempts per minute per IP) to prevent brute-force attacks.

**Story PG-03: User Logout**

* **As an** authenticated user,  
* **I want to** be able to log out of the application,  
* **So that** I can securely end my session.  
* **Acceptance Criteria:**  
  1. A "Logout" button must be available in a persistent location (e.g., user profile dropdown in the header).  
  2. Clicking the button clears the user's session state and tokens from the client.  
  3. The user is redirected to the login page.  
  4. The backend will be designed to honor token expiration, with a potential future enhancement to implement a token revocation list for immediate server-side logout.

**Story PG-04: Manage Profile Data**

* **As a** logged-in user,  
* **I want to** view, add, edit, and delete the question-and-answer pairs in my profile,  
* **So that** I can keep my information up-to-date and accurate.  
* **Acceptance Criteria:**  
  1. A "My Profile" page exists and is accessible only to authenticated users.  
  2. The page displays all of the user's UserProfileData in a clear, editable format, likely an interactive data grid.  
  3. Data on this page will be grouped by logical categories (e.g., "Demographics," "Employment History," "Technical Skills") to improve organization.  
  4. Users can create new entries, modify existing answers, and delete obsolete data points.

**Story PG-05: Securely Store External Credentials**

* **As a** logged-in user,  
* **I want to** securely save my usernames and passwords for both my Primary and Scout accounts,  
* **So that** the application can automate tasks on my behalf.  
* **Acceptance Criteria:**  
  1. A "Settings" page contains a secure form for managing external credentials.  
  2. The form has separate, clearly labeled sections for "Primary Account" and "Scout Account".  
  3. Credentials must be encrypted by the backend using the .NET Data Protection APIs *before* being written to the database. Decrypted credentials must only exist in memory on the server for the brief duration of an automation job.  
  4. The password fields in the UI must be of type password and never display the stored password.

### **Feature: Automation Engine & Scout Protocol**

* **Goal:** Build the core automation functionality. This involves creating the communication pipeline to the Playwright service, proving the concept, and then implementing the innovative "Scout Agent" protocol to handle complex, multi-page surveys.

**Story PG-06: Proof-of-Concept Scraping**

* **As a** user,  
* **I want to** initiate a scan of a simple, single-page survey,  
* **So that** the application can extract all the questions and show them to me.  
* **Acceptance Criteria:**  
  1. A button on the "Studies" page triggers the scraping process.  
  2. The backend successfully calls the Playwright Service, establishing the inter-service communication.  
  3. The Playwright Service proves it can launch a browser, handle the login flow using the provided credentials, navigate to a target URL, and extract the text of all questions on the page.  
  4. The list of questions is successfully returned to the user's UI, proving the entire pipeline works end-to-end for a simple case.

**Story PG-07: Scout a Multi-Page Survey**

* **As a** user,  
* **I want** the "Scout Agent" to be able to navigate a multi-page survey automatically,  
* **So that** it can discover all questions, even those not on the first page.  
* **Acceptance Criteria:**  
  1. The Playwright Service can identify and click common "Next" or "Continue" buttons.  
  2. The service can intelligently provide placeholder answers to required questions to proceed (e.g., select the first radio button, check the first checkbox, enter "N/A" for text fields).  
  3. The service compiles a single, ordered list of all questions discovered across all pages of the survey.  
  4. The scout run terminates successfully when it reaches the final page or can no longer find a "Next" button.

**Story PG-08: Review Unknown Questions from Scout Run**

* **As a** user,  
* **After** a scout run is complete, I want to be presented with a consolidated list of only the questions the system doesn't already know the answer to,  
* **So that** I don't have to answer the same questions over and over again.  
* **Acceptance Criteria:**  
  1. The backend receives the full question list from the Playwright Service.  
  2. It performs a comparison against the user's stored profile data. Initially, this will be based on a direct, case-insensitive string match of the question text.  
  3. A list containing only the unmatched, "unknown" questions is returned to the Blazor UI.  
  4. The user is presented with a clean, user-friendly form to provide answers for only these new questions, which are then saved to their profile.

### **Feature: Primary Application & UX**

* **Goal:** Complete the primary user workflow by filling surveys with the user's real account, and enhance the overall user experience with a polished UI, an informative dashboard, and powerful filtering tools.

**Story PG-09: Fill Survey with Primary Account**

* **As a** user,  
* **After** I have provided all the necessary answers, I want the application to automatically fill out the survey using my primary account credentials,  
* **So that** I can apply for the study quickly and accurately.  
* **Acceptance Criteria:**  
  1. The /fill endpoint on the Playwright service is implemented.  
  2. The backend translates the user's complete set of answers into a structured list of actions (e.g., \[{ "type": "fill", "label": "Job Title", "value": "Product Manager" }, { "type": "check", "label": "Figma", "value": true }\]).  
  3. The Playwright Service successfully logs in with the primary account and executes the action list, filling the entire form in a single, clean pass.  
  4. The UI provides real-time feedback to the user during the filling process, showing a log of actions being performed (e.g., "Filling question 3/15... Success").

**Story PG-10: Build Informative Dashboard**

* **As a** user,  
* **I want** to see a dashboard when I log in,  
* **So that** I can get a quick overview of my profile's status and recent activity.  
* **Acceptance Criteria:**  
  1. A Dashboard page is the default view after login.  
  2. The page displays key statistics, such as a profile completeness score (perhaps visualized with a radial progress bar).  
  3. The dashboard includes a list of recommended studies that are a good match for my profile, calculated based on how many questions can be auto-filled.  
  4. A section for "Recent Activity" shows a list of the last few studies the user has applied to.

**Story PG-11: Implement Advanced Study Filtering**

* **As a** user,  
* **I want** to be able to filter and sort the list of available studies,  
* **So that** I can easily find the ones that are most relevant to me.  
* **Acceptance Criteria:**  
  1. The "Studies" page includes controls to filter by payout range using a slider or min/max input fields.  
  2. The page includes a text box to filter by industry or keywords.  
  3. The user can sort the list of studies by multiple criteria: payout (high to low), match score (high to low), or date posted (newest first).

### **Feature: System Hardening & Reliability**

* **Goal:** Make the automation engine robust and reliable by implementing advanced techniques to avoid bot detection and handle errors gracefully. This feature transforms the tool from a prototype into a dependable assistant.

**Story PG-12: Implement Bot-Evasion Techniques**

* **As a** developer,  
* **I want** the Playwright Service to mimic human behavior,  
* **So that** the application is less likely to be detected and blocked.  
* **Acceptance Criteria:**  
  1. Randomized delays (e.g., between 500ms and 1500ms) are integrated between key actions like page navigation and button clicks.  
  2. Text entry simulates human typing by using PressSequentiallyAsync with a small, randomized delay between keystrokes.  
  3. The browser automation uses a realistic fingerprint: it runs in headed mode on a virtual frame buffer (Xvfb) on the server, uses a common user-agent, and sets a standard viewport size.  
  4. The service implements stateful session handling by logging in once, saving the session state, and injecting it into subsequent jobs to appear as a returning user.

**Story PG-13: Handle CAPTCHAs Gracefully**

* **As a** user,  
* **If** the automation encounters a CAPTCHA, I want the system to pause and notify me,  
* **So that** I can solve it manually and allow the automation to continue.  
* **Acceptance Criteria:**  
  1. The Playwright Service is programmed to detect common selectors associated with CAPTCHA providers (e.g., reCAPTCHA, hCaptcha).  
  2. Upon detection, the service immediately halts, takes a screenshot of the current page, and returns a specific error response to the backend.  
  3. The Blazor UI presents a modal dialog to the user, displaying the screenshot and clear instructions to solve the CAPTCHA in a separate, manual browser session.

**Story PG-14: Implement Interactive Fallback Mode (Stretch Goal)**

* **As a** user,  
* **If** a Scout run fails for any reason, I want the option to try applying in a real-time "interactive mode",  
* **So that** I still have a way to complete my application.  
* **Acceptance Criteria:**  
  1. A SignalR-based communication channel is implemented between the backend and Playwright service for real-time, bi-directional messaging.  
  2. When a user opts-in to this mode (e.g., after a Scout failure), the automation starts and feeds the UI questions one by one as they are discovered.  
  3. The automation pauses and waits for the user to provide an answer before proceeding to the next question, creating an interactive, guided experience.