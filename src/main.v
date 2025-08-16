module main

import veb

pub struct Task {
pub:
	task_id		int
pub mut:
	task_text	string
	task_done	bool
}

pub struct Context {
    veb.Context
}

pub struct App {
	veb.StaticHandler
pub mut: 
	tasks []Task
}

fn main() {
    mut app := &App{
        tasks: []Task{}
    }

	app.handle_static('src/static', true)!
    
	// Pass the App and context type and start the web server on port 8080
    veb.run[App, Context](mut app, 8080)
}

@['/app/tasks'; get]
pub fn (app &App) tasks(mut ctx Context) veb.Result {
	return ctx.html(generate_tasklist(app))
}

@['/app/new_task'; post]
pub fn (mut app App) new_task(mut ctx Context) veb.Result {
	// request method is POST
	new_task:= Task{
		task_id: app.tasks.len
		task_text: ctx.form['task']
		task_done: false
	}

	app.tasks << new_task

	ret := '<div class="todo-container" id="overdiv">
        <h1>To-Do List</h1>
        <form hx-post="/app/new_task" hx-target="#overdiv" hx-swap="outerHTML">
            <input type="text" name="task" placeholder="New task..." required>
            <button type="submit">Add</button>
        </form>
        <ul id="tasks" hx-get="/app/tasks" hx-trigger="load">
            ${generate_tasklist(app)}
        </ul>
    </div>'

	return ctx.html(ret)
}

fn generate_tasklist (app &App) string {
	if app.tasks.len < 1 {
		return '<p>No Tasks</p>'
	}

	mut ret := ''
	for task in app.tasks {
		mut checked := ''
		if task.task_done {
			checked = 'checked'
		}
		ret = ret + '<li data-id="${task.task_id}">
    		<input type="checkbox" name="completed" id="${task.task_id}" ${checked}>
    		<label for="${task.task_id}">${task.task_text}</label>
    		<button class="delete">Delete</button>
			</li>'
	}
	return ret
}