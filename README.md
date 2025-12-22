Roadmap

- [*] Single character and all characters can move and take actions
- [*] Characters can wait for cooldown to finish
- [x] Gather and some other actions can be looped for n times
- [x] Strategy can be added an executed for a character
- [x] Strategies can be executed concurrently for different characters
- [x] Each character should have its own queue of tasks to execute
- [ ] Refactor to relevant classes for better code
- [ ] These tasks can be added on demand for character to take
  - External Thread safe datasource
  - Webserver API to take in new tasks / strategies
  - Use the tasks recived to make the data work
