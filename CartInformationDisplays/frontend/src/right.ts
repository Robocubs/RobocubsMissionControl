import { mount } from 'svelte'
import './right.css'
import Right from './Right.svelte'

const right = mount(Right, {
  target: document.getElementById('right')!,
})

export default right
