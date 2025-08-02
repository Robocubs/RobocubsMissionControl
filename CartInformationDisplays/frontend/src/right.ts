import { mount } from 'svelte'
import './left.css'
import Right from './Right.svelte'

const right = mount(Right, {
  target: document.getElementById('right')!,
})

export default right
