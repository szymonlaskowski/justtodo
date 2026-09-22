import { useEffect, useRef, useState } from 'react'
import { Check, SquareArrowOutUpRight } from 'lucide-react'
import { cn } from 'cn'
import {
  emptyTodo,
  loadTodos,
  openFloatingWindow,
  receiveTodosFromOtherWindow,
  runsInFloatingWindow,
  saveTodos,
} from '@/native'

export default function App() {
  const [todos, setTodos] = useState(loadTodos)
  const inputs = useRef(new Map<string, HTMLInputElement>())
  const inputToFocus = useRef<string | null>(null)
  const todosSharedWithOtherWindow = useRef('')

  useEffect(() => {
    const todosAsJson = JSON.stringify(todos)
    if (todosAsJson === todosSharedWithOtherWindow.current) return

    todosSharedWithOtherWindow.current = todosAsJson
    saveTodos(todos)
  }, [todos])

  useEffect(() => {
    receiveTodosFromOtherWindow((incoming) => {
      todosSharedWithOtherWindow.current = JSON.stringify(incoming)
      setTodos(incoming)
    })
  }, [])

  function registerInput(id: string, input: HTMLInputElement | null) {
    if (input === null) {
      inputs.current.delete(id)
      return
    }

    inputs.current.set(id, input)
    if (inputToFocus.current !== id) return

    inputToFocus.current = null
    input.focus()
    input.setSelectionRange(input.value.length, input.value.length)
  }

  function addAfter(index: number) {
    const fresh = emptyTodo()
    inputToFocus.current = fresh.id
    setTodos((current) => current.toSpliced(index + 1, 0, fresh))
  }

  function removeAt(index: number) {
    if (todos.length === 1) return
    const neighbour = index === 0 ? todos[1] : todos[index - 1]
    inputToFocus.current = neighbour.id
    setTodos((current) => current.toSpliced(index, 1))
  }

  function setText(index: number, text: string) {
    setTodos((current) => current.with(index, { ...current[index], text }))
  }

  function toggleDone(index: number) {
    setTodos((current) => current.with(index, { ...current[index], done: !current[index].done }))
  }

  return (
    <main className="group relative w-[320px] px-4 py-3">
      {!runsInFloatingWindow() && <OpenInWindowButton />}
      <ul>
        {todos.map((todo, index) => (
          <li
            key={todo.id}
            className="flex animate-in cursor-text items-center gap-3 duration-150 fade-in"
            onClick={() => inputs.current.get(todo.id)?.focus()}
          >
            <Checkbox
              checked={todo.done}
              label={todo.text}
              onToggle={() => toggleDone(index)}
            />
            <input
              ref={(input) => registerInput(todo.id, input)}
              value={todo.text}
              placeholder="New todo"
              autoCapitalize="off"
              autoCorrect="off"
              spellCheck={false}
              onChange={(event) => setText(index, event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') {
                  event.preventDefault()
                  addAfter(index)
                }
                if (event.key === 'Backspace' && todo.text === '') {
                  event.preventDefault()
                  removeAt(index)
                }
              }}
              className={cn(
                'h-7 min-w-0 bg-transparent p-0 text-[13px] tracking-[-0.01em] outline-none field-sizing-content selection:bg-white/20 placeholder:text-dim',
                'bg-[linear-gradient(currentColor,currentColor)] bg-[length:0%_1.5px] bg-[position:0_center] bg-no-repeat transition-[background-size,color] duration-[260ms] ease-[cubic-bezier(0.22,1,0.36,1)]',
                todo.done && 'bg-[length:100%_1.5px] text-dim',
              )}
            />
          </li>
        ))}
      </ul>
    </main>
  )
}

function Checkbox({
  checked,
  label,
  onToggle,
}: {
  checked: boolean
  label: string
  onToggle: () => void
}) {
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={checked}
      aria-label={label === '' ? 'New todo' : label}
      onClick={onToggle}
      className={cn(
        'flex size-[15px] shrink-0 cursor-pointer items-center justify-center border text-black transition-[background-color,border-color,transform] duration-200 ease-out active:scale-90',
        checked && 'border-dim bg-dim',
        !checked && label !== '' && 'border-white',
        !checked && label === '' && 'border-dim',
      )}
    >
      {checked && <Check className="size-2.5 animate-in stroke-[3] duration-150 zoom-in-50" />}
    </button>
  )
}

function OpenInWindowButton() {
  return (
    <button
      type="button"
      onClick={openFloatingWindow}
      aria-label="Open in a separate window"
      className="absolute top-2 right-2 cursor-pointer p-1 text-dim opacity-0 transition-[opacity,color] duration-150 group-hover:opacity-100 hover:text-white focus-visible:opacity-100"
    >
      <SquareArrowOutUpRight className="size-3" />
    </button>
  )
}
