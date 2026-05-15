---
name: readme
description: This skill enables the creation of a comprehensive, visually appealing, and professional GitHub README file. The output should match the quality and structure of top-tier open-source projects (e.g., Stripe, Vercel, OpenAI), using clean Markdown formatting and strong visual hierarchy.

---
# Skill: Generate a Professional GitHub README

## Inputs

- **project_name**: Name of the project
- **project_description**: Short summary of the project
- **tech_stack**: Languages, frameworks, and tools used
- **license**: License type (e.g., MIT, Apache 2.0) if exists
- **repository_url** *(optional)*

---

## Output

A polished, structured GitHub README in valid Markdown format, including all required sections and visual enhancements.

---

## Instructions

### 1. Header Section
- Display project name prominently
- Add a one-line value proposition
- Include optional logo placeholder
- Add GitHub badges (build status, license, version, stars)

---

### 2. Table of Contents
- Provide clickable anchor links to all major sections

---

### 3. Overview
- Explain what the project does
- Describe the problem it solves
- Highlight key benefits

---

### 4. Features
- Use clear bullet points
- Emphasize unique or standout capabilities

---

### 5. Architecture (Optional)
- Provide a brief system design explanation if applicable

---

### 6. Installation
Include step-by-step setup instructions:
- Prerequisites
- Clone repository
- Install dependencies
- Run locally

---

### 7. Usage
- Provide code examples
- Include CLI commands or API usage
- Show sample outputs where relevant

---

### 8. Configuration
- List environment variables
- Explain configuration files or settings

---

### 9. Project Structure
- Display folder structure using a tree diagram

---

### 10. Screenshots / Demo
- Include placeholders for images or GIFs

---

### 11. API Documentation (if applicable)
- Describe endpoints, inputs, and outputs

---

### 12. Contributing
- Provide contribution guidelines
- Explain pull request workflow

---

### 13. Roadmap
- List planned features or improvements

---

### 14. FAQ
- Address common questions

---

### 15. License
- Clearly state the license

---

### 16. Acknowledgments
- Credit contributors, tools, or inspirations

---

## Formatting Rules

- Output must be valid Markdown
- Use headings (`#`, `##`, `###`) appropriately
- Include code blocks for commands and examples
- Use tables where helpful
- Add badges at the top
- Use emojis sparingly for readability
- Maintain clean spacing and structure
- Ensure readability on GitHub

---

## Style Guidelines

- Professional and developer-friendly tone
- Clear and concise language
- Avoid unnecessary verbosity
- Match the quality of top open-source documentation

---

## Constraints

- Do NOT include explanations outside the README
- Do NOT include raw instructions in output
- Only return the final Markdown README

---

## Example Use Case

**Input:**
- project_name: "AI Task Manager"
- project_description: "An intelligent task management tool powered by AI"
- tech_stack: "React, Node.js, OpenAI API"
- target_users: "Developers and productivity enthusiasts"
- license: "MIT"

**Output:**
→ A complete, structured README following all sections above

---
