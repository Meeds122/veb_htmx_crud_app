module main

import veb
import db.sqlite

pub struct Task {
pub:
	task_id		int
pub mut:
	task_text	string
	task_done	bool
	task_deleted bool
}

// Context is not shared between requests. It manages the request session
pub struct Context {
    veb.Context
}

// App is shared by all requests. It manages the veb server in whole. 
pub struct App {
	veb.StaticHandler
pub mut: 
	tasks []Task
pub:
	db sqlite.DB
}

// fyi, V has a live reload feature for veb dev: $ v -d veb_livereload watch run .

fn main() {
	// Create our server-wide App struct. 
    mut app := &App{
        tasks: 	[]Task{}
		db: 	sqlite.connect('tasks.db') or { panic(err) }
    }

	// Use V's ORM to create the tasks table or panic.
	// IIRC, V's ORM only creates a new table if one does not exist.
	sql app.db {
        create table Task
    } or { panic(err) }

	// On program startup, read from DB
	db_tasks := sql app.db {
		select from Task
	} or { panic(err) }
	app.tasks = db_tasks

	// Configure the veb.StatiHandler object embedded in the App struct. 
	app.handle_static('src/static', true) or { panic(err) }
    
	// Pass the App and context type and start the web server on port 8080
    veb.run[App, Context](mut app, 8080)
}

// ------------
// -- ROUTES -- 
// ------------

// Read the veb documentation on what becomes a route.
// I like to formally assign a route and methods with the @[] syntax. 
// It is not required for an endpoint to be exposed. This could lead to unexpected 
// API endpoints. 

// CREATE
@['/app/new_task'; post]
pub fn (mut app App) new_task(mut ctx Context) veb.Result {
	// request method is POST
	new_task:= Task{
		task_id: app.tasks.len
		task_text: ctx.form['task']
		task_done: false
		task_deleted: false
	}

	// Appending new_task to the in-memory array of tasks
	// Probably doesn't matter for a simple todo app but 
	// there's no need to hit the DB with a read for every get request. 
	app.tasks << new_task

	// V's ORM, inserting an object into a table.
	sql app.db {
		insert new_task into Task
	} or { panic(err) }

	// Generating the HTML used by HTMX on the frontend
	return ctx.html(generate_overdiv(app))
}

// READ
@['/app/tasks'; get]
pub fn (app &App) tasks(mut ctx Context) veb.Result {
	return ctx.html(generate_tasklist(app))
}

// UPDATE
@['/app/flip/:id'; patch]
pub fn (mut app App) flip(mut ctx Context, id int) veb.Result {
	
	app.tasks[id].task_done = !app.tasks[id].task_done

	sql app.db {
		update Task set task_done = app.tasks[id].task_done where task_id == id
	} or { panic(err) }

	return ctx.html(generate_tasklist(app))
}

// DELETE
@['/app/delete_all'; delete]
pub fn (mut app App) delete_all(mut ctx Context) veb.Result {
	
	for task in app.tasks {
		app.tasks[task.task_id].task_deleted = true

		sql app.db {
			update Task set task_deleted = true where task_id == task.task_id
		} or { panic(err) }
	}

	return ctx.html(generate_overdiv(app))
}

@['/app/delete/:id'; delete]
pub fn (mut app App) delete_task(mut ctx Context, id int) veb.Result {
	
	app.tasks[id].task_deleted = true

	sql app.db {
		update Task set task_deleted = true where task_id == id
	} or { panic(err) }

	return ctx.html(generate_overdiv(app))
}

// ---------------
// -- Functions --
// ---------------

// IIRC, functions need to be public, and reference the App struct in order to be exposed
// as API endpoints. Try accessing http://localhost:8080/generate_tasklist and see that it is not exposed
fn generate_tasklist (app &App) string {
	if app.tasks.len < 1 {
		return '<p>No Tasks</p>'
	}

	mut ret := ''
	for task in app.tasks {
		if task.task_deleted {
			continue // Abort early if 'deleted'. Not a great pattern if worried about regulated data. 
		}
		mut checked := ''
		if task.task_done {
			checked = 'checked'
		}
		ret = ret + '<li data-id="${task.task_id}">
    		<input
				type="checkbox" 
				name="completed" 
				id="${task.task_id}"
				${checked}
				hx-patch="/app/flip/${task.task_id}" 
				hx-target="#tasks" 
				hx-swap="innerHTML"
			>
    		<label for="${task.task_id}">${task.task_text}</label>
    		<button 
				class="delete" 
				hx-delete="/app/delete/${task.task_id}" 
				hx-confirm="Are you sure you want to delete?"
				hx-target="#overdiv"
				hx-swap="outerHTML"
			>
				Delete
			</button>
			</li>'
	}

	// Triggers if all tasks were marked as deleted
	if ret == '' {
		ret = '<p>No Tasks</p>'
	}

	return ret
}

fn generate_overdiv (app &App) string {
	ret := '<div class="todo-container" id="overdiv">
        <h1>To-Do List</h1>
        <form hx-post="/app/new_task" hx-target="#overdiv" hx-swap="outerHTML">
            <input type="text" name="task" placeholder="New task..." required>
            <button type="submit">Add</button>
        </form>
        <ul id="tasks" hx-get="/app/tasks" hx-trigger="load">
            ${generate_tasklist(app)}
        </ul>
		<button 
			class="delete" 
			hx-delete="/app/delete_all" 
			hx-confirm="Are you sure you want to delete ALL tasks?"
			hx-target="#overdiv"
			hx-swap="outerHTML">
			Delete All
		</button>
    </div>'
	return ret
}