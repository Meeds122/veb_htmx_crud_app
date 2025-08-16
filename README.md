# Example veb HTMX CRUD App - The dreaded 'To Do' app!

## Overview
This repository contains a simple CRUD (Create, Read, Update, Delete) application built using V's veb framework and HTMX. The application demonstrates a lightweight, server-side rendered web application with dynamic, interactive front-end components powered by HTMX.

## Features
- Server-side rendering with the V language and veb for fast performance.
- Dynamic client-side interactivity using HTMX without heavy JavaScript frameworks.
- Minimalist and responsive UI.

## Technologies Used
- **veb**: A fast and lightweight web framework for the V programming language.
- **HTMX**: A library for performing AJAX requests, triggering server-side updates, and enabling dynamic behavior with minimal JavaScript.
- **HTML/CSS**: For structuring and styling the user interface.
- **SQLite**: For persistent data storage.

## Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/Meeds122/veb_htmx_crud_app.git
   cd veb_htmx_crud_app
   ```

2. **Install dependencies**:
   Ensure you have the V programming language installed. Follow the [official V installation guide](https://vlang.io/) if needed.
   Install the SQLite dependency. See vlib's SQLite documentation for other operating systems. [vlib - sqlite](https://github.com/vlang/v/tree/master/vlib/db/sqlite)
    ```bash
   apt install -y libsqlite3-dev
   ```

3. **Run the application**:
   ```bash
   v run .
   ```
   The application should now be running at `http://localhost:8080` (or the configured port).
