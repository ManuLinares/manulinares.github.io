module markdown;
import std;

enum BlockState
{
	NONE,
	PARAGRAPH,
	LIST,
	BLOCKQUOTE,
	CODE
}

enum TokenClass : (String name)
{
	KEYWORD    { "k" },
	TYPE       { "kt" },
	CLASS      { "nc" },
	FUNCTION   { "nf" },
	BUILTIN    { "nb" },
	DECORATOR  { "nd" },
	STRING     { "s" },
	CHAR       { "sc" },
	NUMBER     { "m" },
	COMMENT_L  { "c1" },
	COMMENT_M  { "cm" },
	COMMENT_D  { "cd" },
	OPERATOR   { "o" },
	PUNCT      { "p" }
}

fn void append_escaped(DString* out, String text)
{
	foreach (c : text)
	{
		switch (c)
		{
			case '<': out.append_string("&lt;");
			case '>': out.append_string("&gt;");
			case '&': out.append_string("&amp;");
			case '"': out.append_string("&quot;");
			default:  out.append_char(c);
		}
	}
}

fn void append_token(DString* out, TokenClass cls, String text)
{
	out.appendf(`<span class="%s">`, cls.name);
	append_escaped(out, text);
	out.append(`</span>`);
}

fn bool is_c3_keyword(String s)
{
	const String[*] KEYWORDS = {
		"alias", "asm", "assert", "attrmacro", "bitstruct", "break",
		"case", "catch", "const", "continue", "default", "defer",
		"do", "else", "enum", "excuse", "extern", "false", "fn",
		"for", "foreach", "foreach_r", "if", "import", "inline",
		"interface", "macro", "module", "nextcase", "null", "return",
		"static", "struct", "switch", "tlocal", "true", "try",
		"typedef", "union", "var", "while"
	};
	sz idx = sort::binarysearch(KEYWORDS[..], s, &String.compare_to);
	return idx < KEYWORDS.len && KEYWORDS[idx] == s;
}

fn bool is_c3_type(String s)
{
	const String[*] TYPES = {
		"any", "bfloat", "bool", "char", "double", "fault", "float",
		"float128", "float16", "ichar", "int", "int128", "iptr", "long",
		"short", "sz", "typeid", "uint", "uint128", "ulong", "uptr",
		"ushort", "usz", "void"
	};
	sz idx = sort::binarysearch(TYPES[..], s, &String.compare_to);
	return idx < TYPES.len && TYPES[idx] == s;
}

fn bool is_c3_builtin(String s)
{
	const String[*] BUILTINS = {
		"alloc", "alloc_array", "calloc", "free", "free_aligned",
		"malloc", "malloc_aligned", "new", "new_array", "realloc",
		"tcalloc", "tmalloc", "trealloc"
	};
	sz idx = sort::binarysearch(BUILTINS[..], s, &String.compare_to);
	return idx < BUILTINS.len && BUILTINS[idx] == s;
}

fn bool is_operator_char(char c)
{
	switch (c)
	{
		case '+':
		case '-':
		case '*':
		case '/':
		case '%':
		case '&':
		case '|':
		case '^':
		case '~':
		case '!':
		case '=':
		case '<':
		case '>':
		case '?':
		case ':':
		case '.':
			return true;
		default:
			return false;
	}
}

fn void highlight_c3(String code, DString* out)
{
	sz i = 0;
	sz len = code.len;
	while (i < len)
	{
		char c = code[i];
		switch (c)
		{
			case '/':
				if (i + 1 < len)
				{
					switch (code[i + 1])
					{
						case '/':
							sz start = i;
							while (i < len && code[i] != '\n') i++;
							append_token(out, COMMENT_L, code[start : i - start]);
							continue;
						case '*':
							sz start = i;
							i += 2;
							int depth = 1;
							while (i + 1 < len && depth > 0)
							{
								switch
								{
									case code[i] == '/' && code[i + 1] == '*':
										depth++;
										i += 2;
									case code[i] == '*' && code[i + 1] == '/':
										depth--;
										i += 2;
									default:
										i++;
								}
							}
							if (depth > 0) i = len;
							append_token(out, COMMENT_M, code[start : i - start]);
							continue;
						default:
							break;
					}
				}
				append_token(out, OPERATOR, code[i : 1]);
				i++;
				continue;

			case '<':
				if (i + 1 < len && code[i + 1] == '*')
				{
					sz start = i;
					i += 2;
					while (i + 1 < len && !(code[i] == '*' && code[i + 1] == '>')) i++;
					if (i + 1 < len)
					{
						i += 2;
					}
					else
					{
						i = len;
					}
					append_token(out, COMMENT_D, code[start : i - start]);
					continue;
				}
				sz start = i;
				while (i < len && is_operator_char(code[i])) i++;
				append_token(out, OPERATOR, code[start : i - start]);
				continue;

			case '"':
			case '\'':
				sz start = i;
				char quote = c;
				i++;
				while (i < len && code[i] != quote)
				{
					if (code[i] == '\\' && i + 1 < len) i++;
					i++;
				}
				if (i < len && code[i] == quote) i++;
				append_token(out, quote == '"' ? STRING : CHAR, code[start : i - start]);
				continue;

			case '`':
				sz start = i;
				i++;
				while (i < len)
				{
					if (code[i] == '`')
					{
						if (i + 1 < len && code[i + 1] == '`')
						{
							i += 2;
							continue;
						}
						i++;
						break;
					}
					i++;
				}
				append_token(out, STRING, code[start : i - start]);
				continue;

			case '@':
				if (i + 1 < len && (ascii::is_alpha(code[i + 1]) || code[i + 1] == '_'))
				{
					sz start = i;
					i++;
					while (i < len && (ascii::is_alnum(code[i]) || code[i] == '_')) i++;
					append_token(out, DECORATOR, code[start : i - start]);
					continue;
				}
				append_escaped(out, code[i : 1]);
				i++;
				continue;

			case '$':
				if (i + 1 < len)
				{
					sz start = i;
					sz j = i + 1;
					if (j < len && code[j] == '$') j++;
					if (j < len && (ascii::is_alpha(code[j]) || code[j] == '_'))
					{
						while (j < len && (ascii::is_alnum(code[j]) || code[j] == '_')) j++;
						i = j;
						append_token(out, BUILTIN, code[start : i - start]);
						continue;
					}
				}
				append_escaped(out, code[i : 1]);
				i++;
				continue;

			case '0'..'9':
				sz start = i;
				if (c == '0' && i + 1 < len)
				{
					char next = code[i + 1];
					switch (next)
					{
						case 'x':
						case 'X':
						case 'b':
						case 'B':
						case 'o':
						case 'O':
							i += 2;
							while (i < len && (ascii::is_alnum(code[i]) || code[i] == '_')) i++;
							append_token(out, NUMBER, code[start : i - start]);
							continue;
						default:
							break;
					}
				}
				bool has_dot = false;
				while SCAN_NUM: (i < len)
				{
					char ch = code[i];
					switch
					{
						case ch == '.' && !has_dot && i + 1 < len && ascii::is_digit(code[i + 1]):
							has_dot = true;
							i++;
						case ascii::is_digit(ch) || ch == '_':
							i++;
						case (ch == 'e' || ch == 'E') && i + 1 < len:
							i++;
							if (i < len && (code[i] == '+' || code[i] == '-')) i++;
						case ascii::is_alpha(ch):
							i++;
						default:
							break SCAN_NUM;
					}
				}
				append_token(out, NUMBER, code[start : i - start]);
				continue;

			case 'a'..'z':
			case 'A'..'Z':
			case '_':
				sz start = i;
				while (i < len && (ascii::is_alnum(code[i]) || code[i] == '_')) i++;
				String id = code[start : i - start];
				switch
				{
					case is_c3_type(id):
						append_token(out, TYPE, id);
					case is_c3_keyword(id):
						append_token(out, KEYWORD, id);
					case is_c3_builtin(id):
						append_token(out, BUILTIN, id);
					case ascii::is_upper(id[0]):
						append_token(out, CLASS, id);
					default:
						sz j = i;
						while (j < len && (code[j] == ' ' || code[j] == '\t')) j++;
						if (j < len && code[j] == '(')
						{
							append_token(out, FUNCTION, id);
						}
						else
						{
							append_escaped(out, id);
						}
				}
				continue;

			case '(':
			case ')':
			case '[':
			case ']':
			case '{':
			case '}':
			case ',':
			case ';':
				append_token(out, PUNCT, code[i : 1]);
				i++;
				continue;

			case '+':
			case '-':
			case '*':
			case '%':
			case '&':
			case '|':
			case '^':
			case '~':
			case '!':
			case '=':
			case '>':
			case '?':
			case ':':
			case '.':
				sz start = i;
				while (i < len && is_operator_char(code[i])) i++;
				append_token(out, OPERATOR, code[start : i - start]);
				continue;

			default:
				append_escaped(out, code[i : 1]);
				i++;
		}
	}
}

fn void format_inlines(String text, DString* out)
{
	sz i = 0;
	sz len = text.len;
	while (i < len)
	{
		char c = text[i];
		switch (c)
		{
			case '`':
				if (try close = text[i + 1..].index_of_char('`'))
				{
					out.append_string(`<code>`);
					append_escaped(out, text[i + 1 : close]);
					out.append_string(`</code>`);
					i += close + 2;
					continue;
				}
			case '[':
				if (try text_end = text[i + 1..].index_of_char(']'))
				{
					sz open_paren = i + 1 + text_end + 1;
					if (open_paren < len && text[open_paren] == '(')
					{
						if (try paren_end = text[open_paren + 1..].index_of_char(')'))
						{
							String link_text = text[i + 1 : text_end];
							String link_url = text[open_paren + 1 : paren_end];
							out.appendf(`<a href="%s">`, link_url);
							format_inlines(link_text, out);
							out.append(`</a>`);
							i = open_paren + 1 + paren_end + 1;
							continue;
						}
					}
				}
			case '*':
				if (i + 1 < len && text[i + 1] == '*')
				{
					if (try close = text[i + 2..].index_of("**"))
					{
						out.append_string(`<strong>`);
						format_inlines(text[i + 2 : close], out);
						out.append_string(`</strong>`);
						i += close + 4;
						continue;
					}
				}
				if ((i == 0 || text[i - 1] != '*') && (i + 1 < len && text[i + 1] != '*'))
				{
					if (try close = text[i + 1..].index_of_char('*'))
					{
						out.append_string(`<em>`);
						format_inlines(text[i + 1 : close], out);
						out.append_string(`</em>`);
						i += close + 2;
						continue;
					}
				}
			case '<':
				out.append_string("&lt;");
				i++;
				continue;
			case '>':
				out.append_string("&gt;");
				i++;
				continue;
			case '&':
				out.append_string("&amp;");
				i++;
				continue;
			default:
				out.append_char(c);
				i++;
				continue;
		}
		out.append_char(c);
		i++;
	}
}

fn void close_block(BlockState* state, DString* out)
{
	switch (*state)
	{
		case PARAGRAPH:  out.append_string("</p>\n");
		case LIST:       out.append_string("</ul>\n");
		case BLOCKQUOTE: out.append_string("</p></blockquote>\n");
		default:         break;
	}
	*state = NONE;
}

fn String to_html(String md, Allocator allocator) => @pool()
{
	DString out = dstring::temp_with_capacity(md.len * 2);
	DString code_buf = dstring::temp_with_capacity(4096);
	String code_lang = "";
	BlockState state = NONE;

	Splitter lines = md.tokenize_all("\n");

	while (try raw_line = lines.next())
	{
		String line = raw_line.trim_right("\r");

		if (state == CODE)
		{
			if (line.starts_with("```"))
			{
				state = NONE;
				bool is_c3 = code_lang == "c3" || code_lang.starts_with("c3 ") || code_lang == "c" || code_lang.starts_with("c ");
				switch
				{
					case is_c3:
						out.append_string(`<div class="highlight"><pre><code class="language-c3">`);
						highlight_c3(code_buf.str_view(), &out);
						out.append_string("</code></pre></div>\n");
					case code_lang.len > 0:
						out.appendf(`<pre><code class="language-%s">`, code_lang);
						append_escaped(&out, code_buf.str_view());
						out.append_string("</code></pre>\n");
					default:
						out.append_string("<pre><code>");
						append_escaped(&out, code_buf.str_view());
						out.append_string("</code></pre>\n");
				}
				continue;
			}
			code_buf.append_string(line);
			code_buf.append_char('\n');
			continue;
		}

		if (line.trim().len == 0)
		{
			close_block(&state, &out);
			continue;
		}

		switch (line[0])
		{
			case '`':
				if (line.starts_with("```"))
				{
					close_block(&state, &out);
					state = CODE;
					code_lang = line[3..].trim().copy(tmem);
					code_buf.clear();
					continue;
				}
			case '#':
				close_block(&state, &out);
				int level = 0;
				while (level < line.len && line[level] == '#') level++;
				if (level <= 6 && level < line.len && line[level] == ' ')
				{
					String text = line[level + 1..].trim();
					out.appendf(`<h%d>`, level);
					format_inlines(text, &out);
					out.appendf("</h%d>\n", level);
					continue;
				}
			case '-':
			case '*':
				if (line == "---" || line == "***")
				{
					close_block(&state, &out);
					out.append_string("<hr>\n");
					continue;
				}
				if (line.starts_with("- ") || line.starts_with("* "))
				{
					if (state != LIST)
					{
						close_block(&state, &out);
						out.append_string("<ul>\n");
						state = LIST;
					}
					out.append_string(`  <li>`);
					format_inlines(line[2..], &out);
					out.append_string("</li>\n");
					continue;
				}
			case '>':
				if (line.starts_with("> "))
				{
					if (state != BLOCKQUOTE)
					{
						close_block(&state, &out);
						out.append_string(`<blockquote><p>`);
						state = BLOCKQUOTE;
					}
					else
					{
						out.append_char(' ');
					}
					format_inlines(line[2..], &out);
					continue;
				}
			case '<':
				bool is_raw_html = line.starts_with("<details") || line.starts_with("</details>") ||
				                   line.starts_with("<summary") || line.starts_with("</summary>");
				if (is_raw_html)
				{
					close_block(&state, &out);
					out.append_string(line);
					out.append_char('\n');
					continue;
				}
			default:
				break;
		}

		if (state != PARAGRAPH)
		{
			close_block(&state, &out);
			out.append_string("<p>");
			state = PARAGRAPH;
		}
		else
		{
			out.append_char(' ');
		}
		format_inlines(line, &out);
	}

	close_block(&state, &out);
	return out.copy_str(allocator);
}