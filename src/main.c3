module main;
import std, markdown;

struct Post
{
	String title;
	String date;
	String slug;
	String authors;
	String html_body;
}

const String BLOG_START_MARKER = "<!-- BLOG:START -->";
const String BLOG_END_MARKER = "<!-- BLOG:END -->";

<* Sorts posts descending by date *>
fn int cmp_posts(Post* a, Post* b) => b.date.compare_to(a.date);

fn void copy_file_if_exists(String src, String dst)
{
	if (try data = file::load_temp(src)) (void)file::save(dst, data);
}

<* Extracts frontmatter metadata and returns body content *>
fn Post parse_post(String file_content, String fallback_slug) => @pool()
{
	Post post;
	post.slug = fallback_slug;
	post.date = "1970-01-01";
	post.title = fallback_slug;

	if (!file_content.starts_with("---"))
	{
		post.html_body = markdown::to_html(file_content, mem);
		return post;
	}

	sz? closing_marker = file_content[3..].index_of("\n---");
	if (catch closing_marker)
	{
		post.html_body = markdown::to_html(file_content, mem);
		return post;
	}

	String frontmatter = file_content[3 : closing_marker];
	sz body_offset = 3 + closing_marker + 4;
	String body = file_content[body_offset..].trim_left("\r\n");

	Splitter lines = frontmatter.tokenize_all("\n");
	while (try raw_line = lines.next())
	{
		String line = raw_line.trim();
		if (!line.len) continue;

		if (line.starts_with("- "))
		{
			String author = line[2..].trim();
			if (post.authors.len == 0)
			{
				post.authors = author.copy(mem);
			}
			else
			{
				DString combined = dstring::temp_with_capacity(post.authors.len + author.len + 3);
				combined.append_string(post.authors);
				combined.append_string(" & ");
				combined.append_string(author);
				post.authors = combined.copy_str(mem);
			}
			continue;
		}

		sz? colon = line.index_of_char(':');
		if (catch colon) continue;

		String key = line[:colon].trim();
		String val = line[colon + 1..].trim();

		switch
		{
			case key == "title":
				post.title = val.trim(`"`).copy(mem);
			case key == "date":
				post.date = val.copy(mem);
			case key == "slug":
				post.slug = val.copy(mem);
			case key == "authors":
				if (val.len > 0)
				{
					post.authors = val.copy(mem);
				}
			default:
				break;
		}
	}

	post.html_body = markdown::to_html(body, mem);
	return post;
}

<* Emits the standalone post page HTML *>
fn String render_post_page(Post* post, Allocator allocator) => @pool()
{
	DString out = dstring::temp_with_capacity(post.html_body.len + 2048);
	out.appendf(
`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>%s | Manuel Barrio Linares</title>
  <link rel="icon" href="../../avatar.webp" type="image/x-icon">
  <link rel="stylesheet" href="../style.css">
</head>
<body>
  <div class="container">
    <header class="post-header">
      <a href="/" class="nav-back">&larr; Home</a>
      <span class="post-date">%s</span>
    </header>
    <article class="post-content">
      <h1>%s</h1>
%s      <div class="post-footer">
        <span class="post-author">%s</span>
      </div>
    </article>
  </div>
</body>
</html>
`, post.title, post.date, post.title, post.html_body,
		post.authors.len > 0 ? post.authors : "");
	return out.copy_str(allocator);
}

fn int main(String[] args)
{
	// 1. Ensure target build directories exist
	path::mkdir("dist/blog", recursive: true)!!;
	path::mkdir("dist/cv", recursive: true)!!;
	path::mkdir("dist/music/assets", recursive: true)!!;

	// 2. Discover and parse Markdown posts
	List{Post} posts;
	posts.init(mem);
	defer posts.free();

	Path blog_dir = path::tnew("blog")!!;
	PathList? files = path::ls(tmem, blog_dir, no_dirs: true, mask: "*.md", rebase: blog_dir);
	if (try file_list = files)
	{
		foreach (file_path : file_list)
		{
			String base = file_path.basename();
			if (base == "template.md") continue;

			char[]? data = file::load_temp(file_path);
			if (catch err = data)
			{
				io::eprintfn("Failed to read %s: %s", file_path, err);
				continue;
			}

			String slug = base.strip_suffix(".md");

			Post post = parse_post((String)data, slug);
			posts.push(post);
		}
	}

	// 3. Sort posts chronologically (newest first)
	sort::quicksort(posts.array_view(), &cmp_posts);

	// 4. Generate static post artifacts in dist/blog/<slug>/index.html
	Path dist_blog = path::tnew("dist/blog")!!;
	foreach (&post : posts)
	{
		Path post_dir = dist_blog.tappend(post.slug)!!;
		path::mkdir(post_dir, recursive: true)!!;

		String post_html = render_post_page(post, tmem);
		Path out_path = post_dir.tappend("index.html")!!;
		file::save(out_path, post_html)!!;
	}

	// 5. Build blog list fragment for the landing page
	DString blog_fragment = dstring::temp_with_capacity(1024);
	blog_fragment.appendf("%s\n", BLOG_START_MARKER);
	if (posts.len() > 0)
	{
		blog_fragment.append(
`    <div id="blog-section">
      <div class="blog-title">Blog</div>
      <ul class="blog-list">
`);
		foreach (&post : posts)
		{
			blog_fragment.appendf(
`        <li><a href="blog/%s/">%s</a><span class="blog-date">%s</span></li>
`, post.slug, post.title, post.date);
		}
		blog_fragment.append(
`      </ul>
    </div>
`);
	}
	blog_fragment.appendf("    %s", BLOG_END_MARKER);

	// 6. Inject blog list into index.html and write to dist/index.html
	char[]? root_index = file::load_temp("index.html");
	if (try index_content = root_index)
	{
		String idx_str = (String)index_content;
		sz? start_marker = idx_str.index_of(BLOG_START_MARKER);
		sz? end_marker = idx_str.index_of(BLOG_END_MARKER);

		if (try s = start_marker && try e = end_marker)
		{
			sz end_pos = e + BLOG_END_MARKER.len;
			DString final_index = dstring::temp_with_capacity(idx_str.len + blog_fragment.len());
			final_index.append_string(idx_str[:s]);
			final_index.append_string(blog_fragment.str_view());
			final_index.append_string(idx_str[end_pos..]);
			file::save("dist/index.html", final_index.str_view())!!;
		}
		else
		{
			file::save("dist/index.html", index_content)!!;
		}
	}

	// 7. Copy static assets via table
	const Pair{String, String}[*] STATIC_ASSETS = {
		{ "avatar.webp", "dist/avatar.webp" },
		{ "flcl.webp", "dist/flcl.webp" },
		{ "cv/index.html", "dist/cv/index.html" },
		{ "blog/style.css", "dist/blog/style.css" },
		{ "music/index.html", "dist/music/index.html" },
		{ "music/playlist.json", "dist/music/playlist.json" },
	};
	foreach (asset : STATIC_ASSETS)
	{
		copy_file_if_exists(asset.first, asset.second);
	}

	// Copy converted opus tracks
	Path music_assets = path::tnew("music/assets")!!;
	PathList? audio_files = path::ls(tmem, music_assets, no_dirs: true, mask: "*.opus", rebase: music_assets);
	if (try list = audio_files)
	{
		foreach (file_path : list)
		{
			@pool()
			{
				String base = file_path.basename();
				Path dst_path = path::tnew("dist/music/assets")!!.tappend(base)!!;
				copy_file_if_exists((String)file_path, (String)dst_path);
			};
		}
	}

	io::printfn("Successfully generated %d post(s) into ./dist", posts.len());
	return 0;
}