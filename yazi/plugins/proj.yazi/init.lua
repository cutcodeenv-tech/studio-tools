return {
	entry = function()
		local cand = ya.which({
			cands = {
				{ on = "n", desc = "Новый проект" },
				{ on = "s", desc = "Синхронизировать footage" },
				{ on = "p", desc = "Статус проекта" },
				{ on = "c", desc = "Настройки" },
				{ on = "t", desc = "Шаблон папок" },
			},
		})

		if not cand then return end

		local commands = {
			n = "proj new",
			s = "proj sync",
			p = "proj status",
			c = "proj settings",
			t = "proj template",
		}

		local cmd = commands[cand.on]
		if cmd then
			ya.manager_emit("shell", { cmd, block = true })
		end
	end,
}
