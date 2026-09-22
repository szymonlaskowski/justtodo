export type Todo = {
  id: string
  text: string
  done: boolean
}

declare global {
  interface Window {
    __todos?: Todo[]
    __receiveTodos?: (todos: Todo[]) => void
    webkit?: {
      messageHandlers: {
        height: { postMessage: (height: number) => void }
        save: { postMessage: (todosAsJson: string) => void }
        openWindow: { postMessage: (ignored: string) => void }
      }
    }
  }
}

export function emptyTodo(): Todo {
  return { id: crypto.randomUUID(), text: '', done: false }
}

export function loadTodos(): Todo[] {
  const saved = window.__todos
  if (saved === undefined || saved.length === 0) return [emptyTodo()]
  return saved
}

export function saveTodos(todos: Todo[]) {
  window.webkit?.messageHandlers.save.postMessage(JSON.stringify(todos))
}

export function receiveTodosFromOtherWindow(receive: (todos: Todo[]) => void) {
  window.__receiveTodos = receive
}

export function runsInFloatingWindow() {
  return window.location.search.includes('floating')
}

export function openFloatingWindow() {
  window.webkit?.messageHandlers.openWindow.postMessage('')
}

export function syncHeightWithNativeWindow() {
  const native = window.webkit?.messageHandlers.height
  if (native === undefined) return

  const observer = new ResizeObserver(() => {
    native.postMessage(document.body.getBoundingClientRect().height)
  })
  observer.observe(document.body)
}
