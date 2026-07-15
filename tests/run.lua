vim.opt.rtp:prepend(".")
vim.opt.rtp:prepend("tests")

require("tests.test_languages")
require("tests.test_parser")
require("tests.test_search")

require("tests.helpers").summary()
