using HTTP, Gumbo, AbstractTrees, Cascadia, InteractiveUtils, CUDA
nlinks = ["/w/", "//", "/wiki/Category", "/wiki/Portal", "/wiki/File", "/wiki/Help", "/wiki/Wikipedia", "/wiki/Special", '#', "/wiki/Talk", "/wiki/Template", "Main_Page", "/wiki/Special"]
num = 0
country = "the language your wiki pages are in (e.g en, de)"
active = true
src_link = "your starting link"
dest_link = "your final link"
traceback = [src_link]
all_links = [src_link]
function founded()
    global traceback, active
    for links in traceback
        if occursin(dest_link, links)
            links = split(links, ';')
            for link in links
                if link == dest_link
                    print(link)
                    exit(86)
                    break
                end 
                println(link)
            end        
        end
    end  
end
function search(link, linkies)
    @sync begin
    global num
    global active
    v_links = []
    r = HTTP.get(link)
    r_parsed = parsehtml(String(r.body))
    body = r_parsed.root[2]
    link = eachmatch(Selector("a"), body)
    for e1 in link
        try
            e2 = e1.attributes["href"]
            kactive = false
            for ng in nlinks
                if ng == e2
                    kactive = true
                    break
                end
            end
            if !kactive
                if occursin("/wiki", e2)
                    e2 = "https://"*country*".wikipedia.org"*e2
                end
                if occursin("https://"*country, e2)
                    push!(v_links, e2)
                    num = num+1
                end
            end
        catch
        end    
    end
    for link1 in v_links
        dactive = false
        for links in all_links
            if links == link1
                dactive = true
                break
            end
        end
        if !dactive
            push!(traceback, linkies*";"*link1)
            Threads.@spawn begin
                search(link1, linkies*";"*link1)
            end
        if link1 == dest_link
            if active
                founded()
                active = false
            end    
            exit(86)
        end
    end
    end
end
end
search(src_link, src_link)
