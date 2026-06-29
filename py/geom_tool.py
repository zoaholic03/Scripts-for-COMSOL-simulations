"""
COMSOL 几何导出与参数修改工具

用法:
    python geom_tool.py <mph文件路径> [选项]

选项:
    --export-geom PATH       导出几何为 .mphbin 文件
    --param NAME=VALUE       修改参数 (可多次使用)
    --save-as PATH           另存模型为 .mph 文件
    --list-params            列出所有参数
    --component NAME         指定组件名 (默认: comp1)
    --geometry NAME          指定几何序列名 (默认: geom1)
    --output-dir PATH        输出目录 (默认: mph 文件所在目录)

示例:
    python geom_tool.py model.mph --list-params
    python geom_tool.py model.mph --param L=10[mm] --param W=5[mm] --export-geom output.mphbin
    python geom_tool.py model.mph --param voltage=12[V] --save-as modified.mph --export-geom modified.mphbin
"""

import argparse
import os
import sys
import mph


def get_output_path(input_mph, output_name, output_dir, ext):
    if output_dir is None:
        output_dir = os.path.dirname(os.path.abspath(input_mph))
    if output_name is None:
        base = os.path.splitext(os.path.basename(input_mph))[0]
        output_name = f"{base}{ext}"
    if not os.path.isabs(output_name):
        output_name = os.path.join(output_dir, output_name)
    return output_name


def parse_param(param_str):
    if "=" not in param_str:
        raise ValueError(f"参数格式错误，应为 NAME=VALUE: {param_str}")
    name, value = param_str.split("=", 1)
    return name.strip(), value.strip()


def main():
    parser = argparse.ArgumentParser(description="COMSOL 几何导出与参数修改工具")
    parser.add_argument("mph_file", help="输入的 .mph 模型文件路径")
    parser.add_argument("--export-geom", metavar="PATH",
                        help="导出几何为 .mphbin 文件路径")
    parser.add_argument("--param", action="append", metavar="NAME=VALUE",
                        default=[], help="修改参数 (可多次使用)")
    parser.add_argument("--save-as", metavar="PATH",
                        help="另存模型为 .mph 文件路径")
    parser.add_argument("--list-params", action="store_true",
                        help="列出所有参数")
    parser.add_argument("--component", default="comp1",
                        help="组件名 (默认: comp1)")
    parser.add_argument("--geometry", default="geom1",
                        help="几何序列名 (默认: geom1)")
    parser.add_argument("--output-dir", metavar="PATH",
                        help="输出目录 (默认: mph 文件所在目录)")

    args = parser.parse_args()

    if not os.path.isfile(args.mph_file):
        print(f"错误: 文件不存在: {args.mph_file}")
        sys.exit(1)

    print(f"启动 COMSOL 会话...")
    client = mph.start()

    try:
        print(f"加载模型: {args.mph_file}")
        model = client.load(args.mph_file)

        if args.list_params:
            params = model.parameters()
            if params:
                print(f"\n模型参数 (共 {len(params)} 个):")
                for name, expr in params.items():
                    desc = model.description(name) or ""
                    desc_str = f"  # {desc}" if desc else ""
                    print(f"  {name} = {expr}{desc_str}")
            else:
                print("模型中没有定义参数")
            return

        for p in args.param:
            name, value = parse_param(p)
            model.parameter(name, value)
            print(f"参数已修改: {name} = {value}")

        if args.save_as:
            save_path = get_output_path(args.mph_file, args.save_as,
                                        args.output_dir, ".mph")
            model.save(save_path)
            print(f"模型已保存: {save_path}")

        if args.export_geom:
            geom_path = get_output_path(args.mph_file, args.export_geom,
                                        args.output_dir, ".mphbin")
            comp = args.component
            geom = args.geometry
            try:
                model.java.component(comp).geom(geom).export(geom_path)
                print(f"几何已导出: {geom_path}")
            except Exception as e:
                print(f"错误: 导出几何失败: {e}")
                print(f"提示: 请确认组件 '{comp}' 和几何 '{geom}' 存在")
                sys.exit(1)

        if not args.param and not args.save_as and not args.export_geom and not args.list_params:
            parser.print_help()

    finally:
        client.remove(model)


if __name__ == "__main__":
    main()
