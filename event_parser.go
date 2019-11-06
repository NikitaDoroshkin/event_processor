package main

import (
	"bufio"
	"github.com/valyala/fastjson"
	"log"
	"os"
	"runtime"
)

var pp fastjson.ParserPool
var aa fastjson.Arena

func processJson(source string) {
	p := pp.Get()

	val, err := p.Parse(source)
	if err == nil {
		names := val.GetArray("params.name")
		values := val.GetArray("params.string_value")

		if names != nil && values != nil {
			obj := aa.NewObject()

			for i := range names {
				bytes, _ := names[i].StringBytes()
				obj.Set(string(bytes), values[i])
			}
			val.Del("params.name")
			val.Del("params.string_value")
			val.Del("params.double_value")
			val.Set("params", obj)

			go log.Printf(val.String())

			aa.Reset()
		} else {
			go log.Printf(source)
		}
	} else {
		go log.Printf(source)
	}

	pp.Put(p)
}

func main() {
	cores := runtime.NumCPU()
	if runtime.GOMAXPROCS(0) != cores {
		runtime.GOMAXPROCS(cores)
	}

	log.SetFlags(0)

	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		var text = scanner.Text()
		go processJson(text)
	}
}
