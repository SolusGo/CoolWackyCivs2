"""Replay installed BNW Civilopedia indexing; no game UI or cache writes.

The native population functions and IconLookup run unchanged under Lua 5.1.
SQLite supplies GameInfo/DB; localization and native event/vector APIs have
small adapters. This verifies indexing and search, not rendered UI acceptance.
"""
import hashlib
from lupa.lua51 import LuaRuntime
from validate_urgal import support_source


def replay_index(database, translations):
    assets = support_source().parent.parent
    native = assets / 'DLC/Expansion2/UI/Civilopedia/CivilopediaScreen.lua'
    source = native.read_text(encoding='utf-8-sig')
    lua = LuaRuntime(unpack_returned_tuples=True)
    globals_ = lua.globals()

    def rows(sql, parameters=(), booleans=()):
        result = []
        for row in database.execute(sql, parameters):
            fields = dict(row)
            for key in booleans:
                if fields.get(key) is not None:
                    fields[key] = bool(fields[key])
            result.append(lua.table_from(fields))
        return lua.table_from(result)

    make_table = lua.eval('''function(all, query)
      local t={}
      for _,r in ipairs(all)do
        if r.ID~=nil then t[r.ID]=r end
        if r.Type then t[r.Type]=r end
      end
      return setmetatable(t,{__call=function(self,filter)
        local data=all
        if type(filter)=='string' then data=query(filter)end
        local i=0
        return function()
          while i<#data do
            i=i+1;local r=data[i];local ok=true
            if type(filter)=='table' then
              for k,v in pairs(filter)do if r[k]~=v then ok=false end end
            end
            if ok then return r end
          end
        end
      end})
    end''')

    def get_table(name):
        booleans = [r[1] for r in database.execute('PRAGMA table_info("' + name + '")')
                    if r[2].upper() in ('BOOLEAN', 'BOOL')]
        sql = 'SELECT * FROM "' + name + '"'
        return make_table(rows(sql, booleans=booleans),
                          lambda where: rows(sql + ' WHERE ' + where, booleans=booleans))

    # Passing a NULL key through makes native Lua indexing reject it. Unresolved
    # non-NULL keys retain their spelling, as in Civ V's localization fallback.
    globals_.PediaTable = get_table
    globals_.PediaQuery = lambda sql, *params: rows(sql, params)
    globals_.PediaText = lambda key, *args: translations.get(key, key)
    lua.execute('''
      function include()end
      function Vector2(x,y)return{x=x,y=y}end
      Events=setmetatable({},{__index=function()return{Add=function()end}end})
      table.count=function(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
      GameInfo=setmetatable({},{__index=function(t,k)
        local v=PediaTable(k);rawset(t,k,v);return v
      end})
      Locale={ConvertTextKey=PediaText,ToLower=string.lower,
        Compare=function(a,b)
          a=string.lower(a);b=string.lower(b)
          return a==b and 0 or(a<b and -1 or 1)
        end}
      DB={Query=function(sql,...)
        local data=PediaQuery(sql,...);local i=0
        return function()i=i+1;return data[i]end
      end}
      DB.CreateQuery=function(sql)return function(...)return DB.Query(sql,...)end end
    ''')
    support = assets / 'UI/IconSupport.lua'
    lua.execute(support.read_text(encoding='utf-8-sig'), name=str(support))
    # Preserve the native locals and source line numbers while omitting UI
    # registration. All sixteen PopulateList bodies execute without rewriting.
    header_end = source.index('-- the instance managers')
    start = source.index('CivilopediaCategory[CategoryHomePage].PopulateList = function()')
    end = source.index('CivilopediaCategory[CategoryHomePage].DisplayHomePage = function()')
    code = (source[:header_end] + 'for i=1,numCategories do CivilopediaCategory[i]={} end\n'
            + '\n' * (source[header_end:start].count('\n') - 1) + source[start:end])
    code += '\nPediaReplay={categories=CivilopediaCategory,search=searchableList}\n'
    lua.execute(code, name=str(native))
    state = globals_.PediaReplay
    result = {'source': 'Assets/DLC/Expansion2/UI/Civilopedia/CivilopediaScreen.lua',
              'source_sha256': hashlib.sha256(native.read_bytes()).hexdigest(),
              'completed_categories': [], 'failed_category': None}
    for category in range(1, 17):
        try:
            state.categories[category].PopulateList()
            result['completed_categories'].append(category)
        except Exception as exc:
            result.update(failed_category=category, error=str(exc))
            break
    result['search'] = {}
    for name in ('jin', 'wanyan aguda', 'clones of sjin'):
        article = state.search[name]
        result['search'][name] = (None if article is None else
                                 {key: article[key] for key in ('entryName', 'entryID', 'entryCategory')})
    return result
