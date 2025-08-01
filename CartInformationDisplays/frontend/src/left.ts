import { mount } from 'svelte'
import './left.css'
import Left from './Left.svelte'

const left = mount(Left, {
  target: document.getElementById('left')!,
})

export default left
