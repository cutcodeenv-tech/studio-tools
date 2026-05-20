return {
	entry = function()
		local cand = ya.which({
			cands = {
				{ on = "1", desc = "Новый проект" },
				{ on = "2", desc = "Синхронизировать footage" },
				{ on = "3", desc = "Статус проекта" },
				{ on = "4", desc = "Настройки" },
				{ on = "5", desc = "Шаблон папок" },
			},
		})

		if not cand then return end

		local commands = {
			"proj new",
			"proj sync",
			"proj status",
			"proj settings",
			"proj template",
		}

		local cmd = commands[cand]
		if cmd then
			ya.emit("shell", { cmd, block = true })
		end
	end,
}
