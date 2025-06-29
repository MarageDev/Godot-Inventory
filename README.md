<div align="center">
	<!-- <img src="logo svg link" alt="Logo" width="100"> -->
  <h1 align="center">Godot Inventory System (GIS)</h1>
  <h3>
    An attempt at creating a simple and modular inventory system in Godot 
  </h3>
  <h6>Pronunced like "geez"</h6>
</div>
<br>

# Description
This is an inventory system I'm building mainly for my game Dead By Gun Smoke but I'm making it modular as my goal is to make it easy to use 
for many things with inventory-like interactions by exposing most of the main actions so it's possible to build your own logic without being restrcited to the general inventory one.

This is a slot inventory. In the future I'm going to see if it's possible to expand it to a grid one but this isn't the plan yet.

# Features
- ***Drag*** and ***drop***
- ***Stack splitting*** : CTRL + Left click x times to select x items to move
- ***Quick switch*** from one inventory to another : SHIFT + Left click
- ***Auto sorting*** ( depending on custom sorting parameters )
- A lot of ***information exposed through signals*** for an easier integration
- An ***example scene*** to showcase a common inventory layout with mechanics
- Items are managed as ***`Resources`*** for an easier maintainability, saving and loading in general
- Slots store an array of items, so it's easy to access any of them. In the future I'll add the possibility to save only the amount instead for a more performant approach on stacks of the same items.

# Documentation
> Coming soon

> You can check the example script, it contains most of the useful information
# Screenshots
## Development screenshot
![image](https://github.com/user-attachments/assets/7d62cf90-691e-480e-a229-c23cf814b31b)
